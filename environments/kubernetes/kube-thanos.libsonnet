local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';
local service = k.core.v1.service;
local sts = k.apps.v1.statefulSet;
local deployment = k.apps.v1.deployment;

(import 'kube-thanos/kube-thanos-querier.libsonnet') +
(import 'kube-thanos/kube-thanos-store.libsonnet') +
(import 'kube-thanos/kube-thanos-receive.libsonnet') +
// (import 'kube-thanos/kube-thanos-pvc.libsonnet') +
(import '../../components/thanos-receive-controller.libsonnet') +
{
  thanos+:: {
    variables+:: {
      image: 'improbable/thanos:v0.5.0',
      objectStorageConfig+: {
        name: 'thanos-objectstorage',
        key: 'thanos.yaml',
      },
    },

    local namespace = 'observatorium',

    querier+: {
      service+:
        service.mixin.metadata.withNamespace(namespace),
      deployment+:
        deployment.mixin.metadata.withNamespace(namespace) +
        deployment.mixin.spec.withReplicas(3),
    },
    store+: {
      service+:
        service.mixin.metadata.withNamespace(namespace),
      statefulSet+:
        sts.mixin.metadata.withNamespace(namespace) +
        sts.mixin.spec.withReplicas(3),
    },
    receive+: {
      service+:
        service.mixin.metadata.withNamespace(namespace),
      statefulSet+: {
        metadata+: {
          namespace: namespace,
        },
        spec+: {
          replicas: 3,
          template+: {
            spec+: {
              // This patch should probably move upstream to kube-thanos
              containers: [
                super.containers[0] {
                  args+: [
                    '--tsdb.retention=6h',
                  ],
                },
              ],
            },
          },
        },
      },
    },
  },
}
