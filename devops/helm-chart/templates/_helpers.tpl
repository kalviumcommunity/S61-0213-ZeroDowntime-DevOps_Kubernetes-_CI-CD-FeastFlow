{{- define "feastflow-app.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "feastflow-app.fullname" -}}
{{ include "feastflow-app.name" . }}
{{- end -}}
