{{/* vim: set filetype=mustache: */}}
{{/*
Copyright 2018-present Open Networking Foundation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}
{{- define "mcord.fixtureTosca" -}}
tosca_definitions_version: tosca_simple_yaml_1_0

imports:
  - custom_types/site.yaml

description: set up site and deployment and link them

topology_template:
  node_templates:

    {{ .Values.cordSiteName }}:
      type: tosca.nodes.Site
      properties:
          name: {{ .Values.cordSiteName }}
          site_url: http://mysite.opencord.us/
          hosts_nodes: true

{{- end -}}

{{- define "mcord.onosTosca" -}}
tosca_definitions_version: tosca_simple_yaml_1_0

imports:
   - custom_types/onosapp.yaml
   - custom_types/onosservice.yaml
   - custom_types/serviceinstanceattribute.yaml

description: Configures the VOLTHA ONOS service

topology_template:
  node_templates:

    service#onos:
      type: tosca.nodes.ONOSService
      properties:
          name: onos
          kind: data
          rest_hostname: {{ .onosRestService | quote }}
          rest_port: 8181

    onos_app#segmentrouting:
      type: tosca.nodes.ONOSApp
      properties:
        name: org.onosproject.segmentrouting
        app_id: org.onosproject.segmentrouting
      requirements:
        - owner:
            node: service#onos
            relationship: tosca.relationships.BelongsToOne

    onos_app#netcfghostprovider:
      type: tosca.nodes.ONOSApp
      properties:
        name: org.onosproject.netcfghostprovider
        app_id: org.onosproject.netcfghostprovider
      requirements:
        - owner:
            node: service#onos
            relationship: tosca.relationships.BelongsToOne

    onos_app#openflow:
      type: tosca.nodes.ONOSApp
      properties:
        name: org.onosproject.openflow
        app_id: org.onosproject.openflow
      requirements:
        - owner:
            node: service#onos
            relationship: tosca.relationships.BelongsToOne
{{- end -}}

{{- define "mcord.serviceGraphTosca" -}}
tosca_definitions_version: tosca_simple_yaml_1_0

imports:
   - custom_types/fabricservice.yaml
   - custom_types/mcordsubscriberservice.yaml
   - custom_types/onosservice.yaml
{{- if .Values.progran.enabled }}
   - custom_types/progranservice.yaml
{{- end }}
   - custom_types/vrouterservice.yaml
   - custom_types/servicegraphconstraint.yaml
   - custom_types/servicedependency.yaml
   - custom_types/service.yaml

description: Configures the M-CORD service graph

topology_template:
  node_templates:
{{ if .Values.progran.enabled }}
    service#progran:
      type: tosca.nodes.ProgranService
      properties:
        name: progran
        must-exist: true
{{ end }}
    service#vrouter:
      type: tosca.nodes.VRouterService
      properties:
        name: vrouter
        must-exist: true

    service#mcord:
      type: tosca.nodes.MCordSubscriberService
      properties:
        name: mcord
        must-exist: true

    service#onos:
      type: tosca.nodes.ONOSService
      properties:
        name: onos
        must-exist: true

    service#fabric:
      type: tosca.nodes.FabricService
      properties:
        name: fabric
        must-exist: true

    service#omec-cp:
      type: tosca.nodes.Service
      properties:
        name: omec-cp

    service#omec-up:
      type: tosca.nodes.Service
      properties:
        name: omec-up

    service#cdn-local:
      type: tosca.nodes.Service
      properties:
        name: cdn-local

    service#cdn-remote:
      type: tosca.nodes.Service
      properties:
        name: cdn-remote

    service_dependency#onos-fabric_fabric:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#fabric
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#onos
            relationship: tosca.relationships.BelongsToOne

    service_dependency#vrouter_fabric:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#vrouter
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#fabric
            relationship: tosca.relationships.BelongsToOne

{{ if .Values.progran.enabled }}
    service_dependency#mcord_progran:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#progran
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#mcord
            relationship: tosca.relationships.BelongsToOne

    service_dependency#progran_epc_cp:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#omec-cp
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#progran
            relationship: tosca.relationships.BelongsToOne

    service_dependency#progran_epc_up:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#omec-up
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#progran
            relationship: tosca.relationships.BelongsToOne

{{ else }}
    service_dependency#mcord_epc_cp:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#omec-cp
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#mcord
            relationship: tosca.relationships.BelongsToOne

    service_dependency#mcord_epc_up:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#omec-up
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#mcord
            relationship: tosca.relationships.BelongsToOne
{{ end }}

    service_dependency#epc_cp_epc_up:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#omec-up
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#omec-cp
            relationship: tosca.relationships.BelongsToOne

    service_dependency#epc_up_cdn_local:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#cdn-local
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#omec-up
            relationship: tosca.relationships.BelongsToOne

    service_dependency#cdn_local_cdn_remote:
      type: tosca.nodes.ServiceDependency
      properties:
        connect_method: none
      requirements:
        - subscriber_service:
            node: service#cdn-remote
            relationship: tosca.relationships.BelongsToOne
        - provider_service:
            node: service#cdn-local
            relationship: tosca.relationships.BelongsToOne

    constraints:
      type: tosca.nodes.ServiceGraphConstraint
      properties:
{{ if (.Values.seba.enabled) and (.Values.progran.enabled) }}
        constraints: '[ ["mcord", null, "onos"], ["progran", null, "fabric"], ["omec-cp", null, null] ["omec-up", null, null] ]'
{{ else if (not .Values.seba.enabled) and (.Values.progran.enabled) }}
        constraints: '[ ["mcord", "progran", null], ["omec-cp", "omec-up", "onos"], [null, "cdn-local", "fabric"], [null, "cdn-remote", "vrouter"] ]'
{{ else if (not .Values.seba.enabled) and (not .Values.progran.enabled) }}
        constraints: '[ [null, "mcord", null], ["omec-cp", "omec-up", "onos"], [null, "cdn-local", "fabric"], [null, "cdn-remote", "vrouter"] ]'
{{ end }}
{{- end -}}