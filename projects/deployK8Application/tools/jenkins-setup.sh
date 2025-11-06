#!/bin/bash
set -euo pipefail

JENKINS_HOME="/var/lib/jenkins"
INIT_SCRIPT_DIR="$JENKINS_HOME/init.groovy.d"
PLUGIN_FILE="$JENKINS_HOME/plugins.txt"
GROOVY_SCRIPT="$INIT_SCRIPT_DIR/basic-security.groovy"

# Ensure Jenkins is running so secrets are generated
if ! systemctl is-active --quiet jenkins; then
  echo "Starting Jenkins to generate initial secrets..."
  sudo systemctl start jenkins
  # Wait for initial password file (max 60 sec)
  for i in {1..60}; do
    if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
      break
    fi
    sleep 1
  done
fi

# 1. Skip the setup wizard
echo "Skipping Jenkins setup wizard..."
sudo touch "$JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"

# 2. Create init.groovy.d directory
sudo mkdir -p "$INIT_SCRIPT_DIR"

# 3. Deploy Groovy script to configure admin user
sudo tee "$GROOVY_SCRIPT" > /dev/null << 'EOF'
import jenkins.model.*
import hudson.security.*
import jenkins.security.ApiTokenProperty

def instance = Jenkins.getInstance()

// Create/overwrite admin user with password 'xpto'
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "xpto")
instance.setSecurityRealm(hudsonRealm)

def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF

sudo chown -R jenkins:jenkins "$INIT_SCRIPT_DIR"

# 4. Prepare and install plugins
sudo tee "$PLUGIN_FILE" > /dev/null << 'EOF'
pipeline-stage-view:latest
EOF

echo "Installing plugins via jenkins-plugin-cli..."
sudo -u jenkins jenkins-plugin-cli --plugin-file "$PLUGIN_FILE"

# 5. Restart Jenkins to apply everything
echo "Restarting Jenkins..."
sudo systemctl restart jenkins

# 6. Wait for Jenkins to be ready
echo "Waiting for Jenkins to become ready..."
for i in {1..120}; do
  if curl -s http://localhost:8080/login > /dev/null; then
    echo "✅ Jenkins is ready!"
    echo "Login at: http://<your-ec2-public-ip>:8080"
    echo "Username: admin"
    echo "Password: xpto"
    exit 0
  fi
  sleep 2
done

echo "❌ Jenkins did not start in time. Check logs with: sudo journalctl -u jenkins"
exit 1