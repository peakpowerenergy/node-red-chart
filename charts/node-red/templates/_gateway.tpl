{{/*
Gateway API objects. listenerSet holds only the ListenerSet spec and gateway,
routes is a list of HTTPRoute and HTTPSRedirect entries, and routeDefaults holds
the policies applied to every HTTPRoute.
*/}}

{{/*
These keys would otherwise be ignored without a warning.
*/}}
{{- define "node-red.gateway.removedKeys" -}}
{{- $listenerSet := .Values.listenerSet | default dict -}}
{{- if hasKey $listenerSet "enabled" -}}
{{- fail "listenerSet.enabled is not supported. The ListenerSet renders when listeners is set, and routes render on their own" -}}
{{- end -}}
{{- range $key := list "httpRoute" "grpcRoute" "tlsRoute" "tcpRoute" "udpRoute" "httpRedirect" -}}
{{- if get $listenerSet $key -}}
{{- fail (printf "listenerSet.%s is not supported. Use the routes list" $key) -}}
{{- end -}}
{{- end -}}
{{- range $key := list "clientSettings" "proxySettings" "cors" "externalAuth" -}}
{{- if get $listenerSet $key -}}
{{- fail (printf "listenerSet.%s is not supported. Use routeDefaults.%s" $key $key) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "node-red.gateway.validate" -}}
{{- include "node-red.gateway.removedKeys" . -}}
{{- $listeners := .Values.listenerSet.listeners | default list -}}
{{- if and .Values.ingress .Values.ingress.enabled (or $listeners .Values.routes) -}}
{{- fail "ingress.enabled can't be true while listenerSet.listeners or routes are set" -}}
{{- end -}}
{{- $seen := list -}}
{{- range $route := (.Values.routes | default list) -}}
{{- if not (has (toString $route.type) (list "HTTPRoute" "HTTPSRedirect")) -}}
{{- fail (printf "routes entry %s needs a type of HTTPRoute or HTTPSRedirect" ($route.name | default "with no name")) -}}
{{- end -}}
{{- $id := include "node-red.routes.name" (list $ $route) -}}
{{- if has $id $seen -}}
{{- fail (printf "routes has two entries that render HTTPRoute/%s, so one needs its own name" $id) -}}
{{- end -}}
{{- $seen = append $seen $id -}}
{{- end -}}
{{- if and $listeners (not .Values.listenerSet.parentRef) (or (not .Values.listenerSet.gateway) (not .Values.listenerSet.gateway.name) (not .Values.listenerSet.gateway.namespace)) -}}
{{- fail "listenerSet.gateway.name and listenerSet.gateway.namespace are required when listenerSet.parentRef is empty" -}}
{{- end -}}
{{- $proxy := .Values.routeDefaults.proxySettings | default dict -}}
{{- include "node-red.gateway.checkBuffers" (dict "source" "routeDefaults.proxySettings" "bufferSize" (dig "buffering" "bufferSize" "4k" $proxy) "number" (dig "buffering" "buffers" "number" 8 $proxy) "size" (dig "buffering" "buffers" "size" "4k" $proxy) "busy" (dig "buffering" "busyBuffersSize" "" $proxy)) -}}
{{- end -}}

{{- define "node-red.nginx.sizeBytes" -}}
{{- $size := toString . | lower -}}
{{- $digits := regexFind "^[0-9]+" $size -}}
{{- $units := dict "" 1 "k" 1024 "m" 1048576 "g" 1073741824 -}}
{{- $unit := trimPrefix $digits $size -}}
{{- if or (not $digits) (not (hasKey $units $unit)) -}}
{{- fail (printf "invalid nginx size %q" $size) -}}
{{- end -}}
{{- mul (int $digits) (get $units $unit) -}}
{{- end -}}

{{/*
Applies the proxy_busy_buffers_size limits from nginx. NGF only validates these
when busyBuffersSize is set, and a config that fails nginx -t sets the whole
Gateway to Programmed=False. Unset values use the nginx defaults for 4k pages.
*/}}
{{- define "node-red.gateway.checkBuffers" -}}
{{- $buffer := include "node-red.nginx.sizeBytes" .bufferSize | int -}}
{{- $one := include "node-red.nginx.sizeBytes" .size | int -}}
{{- $largest := max $buffer $one | int -}}
{{- $busy := mul 2 $largest | int -}}
{{- if .busy -}}
{{- $busy = include "node-red.nginx.sizeBytes" .busy | int -}}
{{- end -}}
{{- $limit := mul (sub (int .number) 1) $one | int -}}
{{- if or (lt $busy $largest) (gt $busy $limit) -}}
{{- fail (printf "%s buffering would fail nginx -t and freeze the Gateway: busy buffers are %d bytes, which must be at least %d (the larger of bufferSize and buffers.size) and at most %d ((buffers.number - 1) * buffers.size)" .source $busy $largest $limit) -}}
{{- end -}}
{{- end -}}

{{- define "node-red.gateway.fullname" -}}
{{ include "node-red.fullname" . }}
{{- end -}}

{{- define "node-red.gateway.labels" -}}
{{ include "node-red.labels" . }}
{{- end -}}

{{- define "node-red.gateway.hostnames" -}}
{{- $root := index . 0 -}}
{{- $route := index . 1 -}}
{{- $hosts := list -}}
{{- if $route.hostnames -}}
{{- $hosts = $route.hostnames -}}
{{- else -}}
{{- range ($root.Values.listenerSet.listeners | default list) -}}
{{- if and .hostname (or (eq (toString .protocol) "HTTP") (eq (toString .protocol) "HTTPS")) (not (has (toString .hostname) $hosts)) -}}
{{- $hosts = append $hosts (toString .hostname) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if not $hosts -}}
{{- fail "an HTTPRoute needs hostnames, or a listener with a hostname" -}}
{{- end -}}
{{- toYaml $hosts -}}
{{- end -}}

{{/*
A route with no name renders <fullname>, and an HTTPSRedirect renders
<fullname>-http. A named route renders <fullname>-<name>.
*/}}
{{- define "node-red.routes.name" -}}
{{- $fullname := include "node-red.gateway.fullname" (index . 0) -}}
{{- $route := index . 1 -}}
{{- $name := $route.name -}}
{{- if and (not $name) (eq (toString $route.type) "HTTPSRedirect") -}}
{{- $name = "http" -}}
{{- end -}}
{{- if $name -}}{{ printf "%s-%s" $fullname $name }}{{- else -}}{{ $fullname }}{{- end -}}
{{- end -}}

{{/*
Names of the HTTPRoutes that proxy to a backend, as a JSON list. The policies
target these.
*/}}
{{- define "node-red.routes.proxied" -}}
{{- $out := list -}}
{{- range $route := (.Values.routes | default list) -}}
{{- if and (eq (toString $route.type) "HTTPRoute") (ne (toString $route.enabled) "false") -}}
{{- $out = append $out (include "node-red.routes.name" (list $ $route)) -}}
{{- end -}}
{{- end -}}
{{- toJson $out -}}
{{- end -}}

{{- define "node-red.gateway.snippetFilter" -}}
{{- if and .Values.routeDefaults.cors .Values.routeDefaults.cors.enabled }}
- type: ExtensionRef
  extensionRef:
    group: gateway.nginx.org
    kind: SnippetsFilter
    name: {{ include "node-red.gateway.fullname" . }}-snippets
{{- end }}
{{- end -}}
