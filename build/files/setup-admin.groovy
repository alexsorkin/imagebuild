import jenkins.model.*
import hudson.security.*
import hudson.util.*
import jenkins.install.*
import jenkins.security.s2m.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.model.Jenkins
import jenkins.model.JenkinsLocationConfiguration

def instance = Jenkins.getInstance()
def env = System.getenv()

def jenkins_url = env['JENKINS_CONSOLE_URL']
def jenkins_email = env['JENKINS_ADMIN_EMAIL']

def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
println "DEBUGGING: currentConfigurationUrl: " + jenkinsLocationConfiguration.getUrl()
println "DEBUGGING: givenLocationConfigurationUrl: " + jenkins_url

if (jenkinsLocationConfiguration.getUrl() != jenkins_url ) {

  def user = env['JENKINS_ADMIN_USER']
  def pass = env['JENKINS_ADMIN_PASSWORD']

  def hudsonRealm = new HudsonPrivateSecurityRealm(false)
  hudsonRealm.createAccount(user,pass)
  instance.setSecurityRealm(hudsonRealm)
  def strategy = new GlobalMatrixAuthorizationStrategy()
  // def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
  // strategy.setAllowAnonymousRead(false)
  strategy.add(Jenkins.ADMINISTER, user)
  instance.setAuthorizationStrategy(strategy)

  instance.injector.getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false);

  instance.setNumExecutors(0)

  def crumbUser = new DefaultCrumbIssuer(
          excludeClientIPFromCrumb=true
  )
  instance.setCrumbIssuer(crumbUser)
  instance.quietPeriod = 0

  if (!instance.installState.isSetupComplete()) {
      InstallState.INITIAL_SETUP_COMPLETED.initializeState()
  }

  instance.save()

//  def jenkinsParameters = [
//    url:    jenkins_url,
//    email:  jenkins_email
//  ]

  jenkinsLocationConfiguration.setUrl(jenkins_url)
  jenkinsLocationConfiguration.setAdminAddress(jenkins_email)

  jenkinsLocationConfiguration.save()

}