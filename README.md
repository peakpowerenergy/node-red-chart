# `node-red ⚙`

[![SIT](https://img.shields.io/badge/SIT-awesome-blueviolet.svg?style=for-the-badge)](https://jobs.schwarz)

![Helm](https://img.shields.io/badge/helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Node-Red](https://img.shields.io/badge/node--red-8F0000?style=for-the-badge&logo=nodered&logoColor=white)

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/SchwarzIT/node-red-chart/chart-publish/main?logo=github&style=for-the-badge)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/node-red&style=for-the-badge)](https://artifacthub.io/packages/search?repo=node-red)

<img src="https://nodered.org/about/resources/media/node-red-icon-2.png" width="80" height="80">

A Helm chart for Node-Red, a low-code programming for event-driven applications

**Homepage:** <https://nodered.org/>

## Usage

Adding node-red repository Before installing any chart provided by this repository, add the node-red Charts Repository:

```bash
helm repo add node-red https://schwarzit.github.io/node-red-chart/
helm repo update
```

### Installing the Chart

To install the chart with the release name node-red run:

```bash
helm install node-red node-red/node-red
```

After a few seconds, node-red should be running.

To install the chart in a specific namespace use following commands:

```bash
kubectl create ns node-red 
helm install node-red node-red/node-red --namespace node-red
```

> **Tip**: List all releases using `helm list`, a release is a name used to track a specific deployment

### Uninstalling the Chart

To uninstall the `node-red` deployment:

```bash
helm uninstall node-red
```

### Configuring the Chart

See the [README](charts/node-red/README.md) for more detailed information.

## Contributing 🤝

#### Contributing via GitHub

Feel free to join. Checkout the [contributing guide](CONTRIBUTING.md)

#### License

Apache License, Version 2.0

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| [@dirien](https://github.com/dirien) | engin.diri@mail.schwarz | https://jobs.schwarz |