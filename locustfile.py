from locust import HttpUser, task
import os
import warnings

# Ignore the warning from the disabled HTTPS certificate verification.
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

class QuickstartUser(HttpUser):
    @task
    def hello_world(self):
        self.client.get("/admin/modules")

    def on_start(self):
        # Disable HTTPS certificate verification.
        self.client.verify = False
        uli_url = os.environ['ULI']
        # Get the path from the login URL.
        uli_path = uli_url.split(self.host, 1)[-1].rstrip()
        # Login via the login path.
        self.client.get(uli_path)
