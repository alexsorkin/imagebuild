import hudson.model.*
import jenkins.model.*
import org.yaml.snakeyaml.Yaml
import org.csanchez.jenkins.plugins.kubernetes.*
import org.csanchez.jenkins.plugins.kubernetes.volumes.workspace.EmptyDirWorkspaceVolume
import org.csanchez.jenkins.plugins.kubernetes.volumes.*
 
//since kubernetes-1.0
import org.csanchez.jenkins.plugins.kubernetes.model.KeyValueEnvVar
//import org.csanchez.jenkins.plugins.kubernetes.PodEnvVar

File confFile = new File (System.getenv("JENKINS_HOME") + '/jenkins_config/kubernetes-clouds.yaml')
if (!confFile.exists()) {
    println "Cloud config file doesn't exist. Exiting script.."
    return
}

Yaml reader = new Yaml()
def conf = reader.load(confFile.text)

Jenkins.instance.clouds.clear()
conf.kubernetes_clouds.each { k8sCloud ->
    def kc
    try {
        println("Configuring kubernetes cloud: '" + k8sCloud.name + "'")
    
        kc = new KubernetesCloud(k8sCloud.name)
        Jenkins.instance.clouds.add(kc)
        println "cloud added: ${Jenkins.instance.clouds}"
    
        kc.setContainerCapStr(k8sCloud.containerCapStr)
        kc.setServerUrl(k8sCloud.serverUrl)
        kc.setSkipTlsVerify(k8sCloud.skipTlsVerify)
        kc.setNamespace(k8sCloud.namespace)
        kc.setJenkinsUrl(k8sCloud.jenkinsUrl)
    //    kc.setCredentialsId(k8sCloud.credentialsId)
        kc.setRetentionTimeout(k8sCloud.retentionTimeout)
        //since kubernetes-1.0
    //    kc.setConnectTimeout(k8sCloud.connectTimeout)
        kc.setReadTimeout(k8sCloud.readTimeout)
        //since kubernetes-1.0
    //    kc.setMaxRequestsPerHostStr(k8sCloud.maxRequestsPerHostStr)
    
        println ("Creating templates..")
        kc.templates.clear()
    
        k8sCloud.podTemplates.each { podTemplateConfig ->
    
            def podTemplate = new PodTemplate()
            podTemplate.setLabel(podTemplateConfig.label)
            podTemplate.setName(podTemplateConfig.name)
    
            if (podTemplateConfig.inheritFrom) podTemplate.setInheritFrom(podTemplateConfig.inheritFrom)
            if (podTemplateConfig.slaveConnectTimeout) podTemplate.setSlaveConnectTimeout(podTemplateConfig.slaveConnectTimeout)
            if (podTemplateConfig.idleMinutes) podTemplate.setIdleMinutes(podTemplateConfig.idleMinutes)
            if (podTemplateConfig.serviceAccount) podTemplate.setServiceAccount(podTemplateConfig.serviceAccount)
            if (podTemplateConfig.nodeSelector) podTemplate.setNodeSelector(podTemplateConfig.nodeSelector)
            //
            //since kubernetes-1.0
    //        if (podTemplateConfig.nodeUsageMode) podTemplate.setNodeUsageMode(podTemplateConfig.nodeUsageMode)
            if (podTemplateConfig.customWorkspaceVolumeEnabled) podTemplate.setCustomWorkspaceVolumeEnabled(podTemplateConfig.customWorkspaceVolumeEnabled)
    
            if (podTemplateConfig.workspaceVolume) {
                if (podTemplateConfig.workspaceVolume.type == 'EmptyDirWorkspaceVolume') {
                    podTemplate.setWorkspaceVolume(new EmptyDirWorkspaceVolume(podTemplateConfig.workspaceVolume.inMemory))
                }
            }
    
            if (podTemplateConfig.volumes) {
                def volumes = []
                podTemplateConfig.volumes.each { volume ->
                    if (volume.type == 'EmptyDirVolume') {
                        volumes << new EmptyDirVolume(volume.mountPath, volume.inMemory) 
                    } else if (volume.type == 'HostPathVolume') {
                        volumes << new HostPathVolume(volume.hostPath, volume.mountPath) 
                    } else if (volume.type == 'SecretVolume') {
                        volumes << new SecretVolume(volume.mountPath, volume.secretName) 
                    } else if (volume.type == 'ConfigMapVolume') {
                        volumes << new ConfigMapVolume(volume.mountPath, volume.configMapName) 
                    }
                }
                podTemplate.setVolumes(volumes) 
            } 
            if (podTemplateConfig.keyValueEnvVar) { 
                def envVars = [] 
                podTemplateConfig.keyValueEnvVar.each { keyValueEnvVar ->
    
                    //since kubernetes-1.0
    //                envVars << new KeyValueEnvVar(keyValueEnvVar.key, keyValueEnvVar.value)
                    envVars << new KeyValueEnvVar(keyValueEnvVar.key, keyValueEnvVar.value)
                }
                podTemplate.setEnvVars(envVars)
            }
    
            if (podTemplateConfig.containerTemplates) {
                def containerTemplates = []
                podTemplateConfig.containerTemplates.each { containerTemplate -> 
                    println "containerTemplate: ${containerTemplate}"
    
                    ContainerTemplate ct = new ContainerTemplate(
                            containerTemplate.name ?: k8sCloud.containerTemplateDefaults.name,
                            containerTemplate.image)
        
                    ct.setAlwaysPullImage(containerTemplate.alwaysPullImage ?: k8sCloud.containerTemplateDefaults.alwaysPullImage)
                    ct.setPrivileged(containerTemplate.privileged ?: k8sCloud.containerTemplateDefaults.privileged)
                    ct.setTtyEnabled(containerTemplate.ttyEnabled ?: k8sCloud.containerTemplateDefaults.ttyEnabled)
                    ct.setWorkingDir(containerTemplate.workingDir ?: k8sCloud.containerTemplateDefaults.workingDir)
                    ct.setArgs(containerTemplate.args ?: k8sCloud.containerTemplateDefaults.args)
                    ct.setResourceRequestCpu(containerTemplate.resourceRequestCpu ?: k8sCloud.containerTemplateDefaults.resourceRequestCpu)
                    ct.setResourceLimitCpu(containerTemplate.resourceLimitCpu ?: k8sCloud.containerTemplateDefaults.resourceLimitCpu)
                    ct.setResourceRequestMemory(containerTemplate.resourceRequestMemory ?: k8sCloud.containerTemplateDefaults.resourceRequestMemory)
                    ct.setResourceLimitMemory(containerTemplate.resourceLimitMemory ?: k8sCloud.containerTemplateDefaults.resourceLimitMemory)
                    ct.setCommand(containerTemplate.command ?: k8sCloud.containerTemplateDefaults.command)
                    containerTemplates << ct
                }
                podTemplate.setContainers(containerTemplates)

            }
    
            println "adding ${podTemplateConfig.name}"
            kc.templates << podTemplate
    
        }
    
        kc = null
        println("Configuring kubernetes cloud: '" + k8sCloud.name + "' completed.")
    }
    finally {
        //if we don't null kc, jenkins will try to serialise k8s objects and that will fail, so we won't see actual error
        kc = null
    }
}