#!/bin/bash
set -euo pipefail

### =========================================================
### Jenkins Full Clean Installation Script
### =========================================================

# --- Configuration ---
ADMIN_USER="admin"
ADMIN_PASS="xpto"
JENKINS_PORT=8080
JENKINS_HOME="/var/lib/jenkins"
INIT_SCRIPT_DIR="$JENKINS_HOME/init.groovy.d"

# =========================================================
# 1. Stop and Remove Any Previous Jenkins Installation
# =========================================================
echo "=== Cleaning up previous Jenkins installation ==="

if systemctl is-active --quiet jenkins; then
  sudo systemctl stop jenkins || true
fi
sudo systemctl disable jenkins || true

# Remove Jenkins packages and files
sudo yum remove -y jenkins || sudo apt-get remove -y jenkins || true

# Remove leftover directories
sudo rm -rf /var/lib/jenkins /var/cache/jenkins /var/log/jenkins /etc/default/jenkins /etc/sysconfig/jenkins /etc/init.d/jenkins /usr/lib/jenkins /usr/share/jenkins || true

echo "✅ Old Jenkins installation removed."

# =========================================================
# 2. Install Java 17 (Amazon Corretto)
# =========================================================
echo "=== Installing Java 17 (Amazon Corretto) ==="
if ! command -v java &>/dev/null; then
  sudo yum install -y java-17-amazon-corretto-devel || sudo apt-get install -y java-17-amazon-corretto-jdk
fi
java -version

# =========================================================
# 3. Install Jenkins LTS
# =========================================================
echo "=== Installing Jenkins LTS ==="
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# =========================================================
# 4. Disable Setup Wizard
# =========================================================
echo "=== Disabling setup wizard ==="
sudo mkdir -p "$INIT_SCRIPT_DIR"

# Make sure environment variable disables the wizard
sudo tee /etc/default/jenkins >/dev/null <<EOF
JAVA_ARGS="-Djenkins.install.runSetupWizard=false"
JENKINS_PORT=$JENKINS_PORT
EOF

# =========================================================
# 5. Create Admin User via Groovy Init Script
# =========================================================
echo "=== Creating admin user init script ==="
sudo tee "$INIT_SCRIPT_DIR/01-create-admin-user.groovy" > /dev/null <<EOF
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()

if (instance.securityRealm.getAllUsers().isEmpty()) {
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    hudsonRealm.createAccount("$ADMIN_USER", "$ADMIN_PASS")
    instance.setSecurityRealm(hudsonRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)

    instance.save()
    println("✅ Jenkins admin user created: $ADMIN_USER")
} else {
    println("ℹ️ Admin user already exists, skipping...")
}
EOF

sudo chown -R jenkins:jenkins "$INIT_SCRIPT_DIR"

# =========================================================
# 6. Preinstall Plugins and their Dependencies
# =========================================================
echo "=== Pre-installing Jenkins plugins ==="
sudo -u jenkins mkdir -p "$JENKINS_HOME/plugins"

# List of Jenkins plugins to install, including dependencies
PLUGINS=(
  "workflow-aggregator"
  "workflow-job"
  "git"
  "credentials"
  "ssh-credentials"
  "scm-api"
  "matrix-project"
  "structs"
  "token-macro"
  "plain-credentials"
  "ws-cleanup"
  "jdk-tool"
  "ant"
  "maven-plugin"
  "pipeline-stage-view"
  "commons-lang3-api"  # Dependency for Ant Plugin
  "commons-text-api"   # Dependency for Token Macro Plugin
  "bouncycastle-api"   # Dependency for SSH Credentials Plugin
  "workflow-step-api"  # Dependency for Pipeline plugins
  "workflow-api"       # Dependency for many Pipeline-related plugins
  "workflow-basic-steps" # Dependency for Pipeline jobs
  "workflow-cps"       # Dependency for Pipeline steps
  "pipeline-rest-api"  # Dependency for Stage View
  "ionicons-api"       # Dependency for several plugins
  "junit"              # Dependency for Jenkins testing
  "script-security"    # Dependency for Matrix Project Plugin
  "apache-httpcomponents-client-4-api" # Required for Maven Plugin
  "jsch"               # Required for Maven Plugin
  "mailer"             # Required for Maven Plugin
  "javadoc"            # Required for Maven Plugin
  "jsoup"              # Required for Maven Plugin
)

for plugin in "${PLUGINS[@]}"; do
  echo "→ Installing plugin: $plugin"
  sudo -u jenkins curl -fsSL -o "$JENKINS_HOME/plugins/${plugin}.jpi" \
    "https://updates.jenkins.io/latest/${plugin}.hpi"
done

sudo chown -R jenkins:jenkins "$JENKINS_HOME/plugins"

# =========================================================
# 7. Mark Setup Wizard Complete
# =========================================================
echo "=== Marking setup wizard as completed ==="
sudo -u jenkins bash -c "echo 2.462 > $JENKINS_HOME/jenkins.install.UpgradeWizard.state"
sudo -u jenkins bash -c "echo 2.462 > $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"
sudo -u jenkins bash -c "touch $JENKINS_HOME/jenkins.install.InstallUtil.installCompleted"

sudo chown -R jenkins:jenkins "$JENKINS_HOME"

# =========================================================
# 8. Enable and Start Jenkins
# =========================================================
echo "=== Enabling and starting Jenkins ==="
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# =========================================================
# 9. Wait for Jenkins to Become Ready
# =========================================================
echo "=== Waiting for Jenkins to become ready (up to 90s) ==="
for i in {1..90}; do
  if curl -s "http://localhost:${JENKINS_PORT}/login" | grep -q "Jenkins"; then
    echo "✅ Jenkins is ready!"
    echo
    echo "Access Jenkins at: http://$(curl -s http://checkip.amazonaws.com):${JENKINS_PORT}"
    echo "Username: ${ADMIN_USER}"
    echo "Password: ${ADMIN_PASS}"
    exit 0
  fi
  sleep 2
done

echo "❌ Jenkins failed to start properly. Check logs: sudo journalctl -u jenkins -f"
exit 1