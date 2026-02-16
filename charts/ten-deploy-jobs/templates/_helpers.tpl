{{- define "ten-deploy-jobs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "ten-deploy-jobs.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "ten-deploy-jobs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "ten-deploy-jobs.labels" -}}
helm.sh/chart: {{ include "ten-deploy-jobs.chart" . }}
app.kubernetes.io/name: {{ include "ten-deploy-jobs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "ten-deploy-jobs.networkJson" -}}
{{- $network := .Values.network -}}
{
  "layer1": {
    "url": "{{ $network.l1HttpUrl }}",
    "useGateway": false,
    "live": false,
    "saveDeployments": true,
    "deploy": [
      "deployment_scripts/core",
      "deployment_scripts/testnet/layer1"
    ],
    "accounts": [ "{{ $network.l1DeployerPrivateKey }}" ]
  },
  "layer2": {
    "url": "http://127.0.0.1:3000/v1/",
    "useGateway": true,
    "live": false,
    "saveDeployments": true,
    "companionNetworks": { "layer1": "layer1" },
    "deploy": [
      "deployment_scripts/funding/layer1",
      "deployment_scripts/bridge/",
      "deployment_scripts/testnet/layer2/"
    ],
    "accounts": [ "{{ $network.l2DeployerPrivateKey }}" ]
  }
}
{{- end }}

{{- define "ten-deploy-jobs.l1NetworkJson" -}}
{{- $network := .Values.network -}}
{
  "layer1": {
    "url": "{{ $network.l1HttpUrl }}",
    "useGateway": false,
    "live": false,
    "saveDeployments": true,
    "accounts": [ "{{ $network.l1DeployerPrivateKey }}" ]
  }
}
{{- end }}
