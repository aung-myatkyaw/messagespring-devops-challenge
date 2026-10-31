{{/*
Labels shared by every object. Resource names are just the release name
("web"), so no name helper is needed.
*/}}
{{- define "web.labels" -}}
{{ include "web.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | trunc 63 | quote }}
app.kubernetes.io/part-of: messagespring
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/*
Selector labels: must never change after the first deploy (a Deployment's
selector is immutable), so the version is not part of them.
*/}}
{{- define "web.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
