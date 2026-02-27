{{/* Generate a fullname for resources */}}
{{- define "feastflow-app.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "feastflow-app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Chart name */}}
{{- define "feastflow-app.name" -}}
feastflow-app
{{- end -}}
