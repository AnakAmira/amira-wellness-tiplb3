"""
Kubernetes deployment module for Amira Wellness backend application.

This module provides utilities for managing Kubernetes manifests, generating deployment
configurations, and deploying the application to Kubernetes clusters. It implements
infrastructure as code principles with environment-specific configuration handling.
"""

import os
import pathlib
import yaml
import jinja2
import kubernetes
import base64

# Constants and paths
K8S_DEPLOY_DIR = pathlib.Path(__file__).parent.absolute()
DEPLOYMENT_PATH = K8S_DEPLOY_DIR / 'deployment.yaml'
SERVICE_PATH = K8S_DEPLOY_DIR / 'service.yaml'
INGRESS_PATH = K8S_DEPLOY_DIR / 'ingress.yaml'
CONFIGMAP_PATH = K8S_DEPLOY_DIR / 'configmap.yaml'
SECRETS_PATH = K8S_DEPLOY_DIR / 'secrets.yaml'
HPA_PATH = K8S_DEPLOY_DIR / 'hpa.yaml'

# Version information
__version__ = '0.1.0'

def load_yaml_template(file_path):
    """
    Loads a YAML template file and returns its contents as a Python dictionary.
    
    Args:
        file_path (pathlib.Path): Path to the YAML template file
        
    Returns:
        dict: The YAML file contents as a Python dictionary
    """
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def get_deployment_template():
    """
    Loads the Kubernetes Deployment manifest template.
    
    Returns:
        dict: The Deployment manifest template as a Python dictionary
    """
    return load_yaml_template(DEPLOYMENT_PATH)

def get_service_template():
    """
    Loads the Kubernetes Service manifest template.
    
    Returns:
        dict: The Service manifest template as a Python dictionary
    """
    return load_yaml_template(SERVICE_PATH)

def get_ingress_template():
    """
    Loads the Kubernetes Ingress manifest template.
    
    Returns:
        dict: The Ingress manifest template as a Python dictionary
    """
    return load_yaml_template(INGRESS_PATH)

def get_configmap_template():
    """
    Loads the Kubernetes ConfigMap manifest template.
    
    Returns:
        dict: The ConfigMap manifest template as a Python dictionary
    """
    return load_yaml_template(CONFIGMAP_PATH)

def get_secrets_template():
    """
    Loads the Kubernetes Secret manifest template.
    
    Returns:
        dict: The Secret manifest template as a Python dictionary
    """
    return load_yaml_template(SECRETS_PATH)

def get_hpa_template():
    """
    Loads the Kubernetes HorizontalPodAutoscaler manifest template.
    
    Returns:
        dict: The HPA manifest template as a Python dictionary
    """
    return load_yaml_template(HPA_PATH)

def render_jinja_template(template_content, variables):
    """
    Renders a Jinja2 template with provided variables.
    
    Args:
        template_content (str): Jinja2 template content
        variables (dict): Variables to substitute in the template
        
    Returns:
        str: Rendered template content
    """
    template = jinja2.Template(template_content)
    return template.render(**variables)

def substitute_template_variables(template, variables):
    """
    Substitutes variables in a template dictionary with provided values.
    
    Args:
        template (dict): Template dictionary
        variables (dict): Variables to substitute
        
    Returns:
        dict: Template with variables substituted
    """
    # Convert template to YAML
    yaml_template = yaml.dump(template)
    
    # Render template with variables
    rendered_yaml = render_jinja_template(yaml_template, variables)
    
    # Convert back to dictionary
    return yaml.safe_load(rendered_yaml)

def encode_secret_data(secret_data):
    """
    Encodes secret data values to base64 for Kubernetes Secret resources.
    
    Args:
        secret_data (dict): Secret data with plain text values
        
    Returns:
        dict: Dictionary with base64-encoded values
    """
    encoded_data = {}
    for key, value in secret_data.items():
        if isinstance(value, str):
            encoded_data[key] = base64.b64encode(value.encode('utf-8')).decode('utf-8')
        else:
            encoded_data[key] = base64.b64encode(str(value).encode('utf-8')).decode('utf-8')
    return encoded_data

def generate_deployment_manifest(variables):
    """
    Generates a Kubernetes Deployment manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated Deployment manifest
    """
    template = get_deployment_template()
    return substitute_template_variables(template, variables)

def generate_service_manifest(variables):
    """
    Generates a Kubernetes Service manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated Service manifest
    """
    template = get_service_template()
    return substitute_template_variables(template, variables)

def generate_ingress_manifest(variables):
    """
    Generates a Kubernetes Ingress manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated Ingress manifest
    """
    template = get_ingress_template()
    return substitute_template_variables(template, variables)

def generate_configmap_manifest(variables):
    """
    Generates a Kubernetes ConfigMap manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated ConfigMap manifest
    """
    template = get_configmap_template()
    return substitute_template_variables(template, variables)

def generate_secrets_manifest(variables):
    """
    Generates a Kubernetes Secret manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated Secret manifest
    """
    template = get_secrets_template()
    manifest = substitute_template_variables(template, variables)
    
    # Encode secret data values if they're not already encoded
    if 'data' in manifest and manifest['data']:
        manifest['data'] = encode_secret_data(manifest['data'])
    
    return manifest

def generate_hpa_manifest(variables):
    """
    Generates a Kubernetes HorizontalPodAutoscaler manifest with environment-specific variables.
    
    Args:
        variables (dict): Variables to substitute in the template
        
    Returns:
        dict: Generated HPA manifest
    """
    template = get_hpa_template()
    return substitute_template_variables(template, variables)

def save_yaml_to_file(data, file_path):
    """
    Saves a Python dictionary as a YAML file.
    
    Args:
        data (dict): Dictionary to save as YAML
        file_path (pathlib.Path): Path to save the YAML file
        
    Returns:
        pathlib.Path: Path to the saved file
    """
    # Create parent directories if they don't exist
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(file_path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False)
    
    return file_path

def generate_kubernetes_manifests(variables, output_dir):
    """
    Generates all Kubernetes manifests for the application.
    
    Args:
        variables (dict): Variables to substitute in the templates
        output_dir (str): Directory to save the generated manifests
        
    Returns:
        dict: Dictionary of generated manifest files and their paths
    """
    output_path = pathlib.Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    generated_files = {}
    
    # Generate and save deployment manifest
    deployment_manifest = generate_deployment_manifest(variables)
    deployment_path = output_path / 'deployment.yaml'
    save_yaml_to_file(deployment_manifest, deployment_path)
    generated_files['deployment'] = deployment_path
    
    # Generate and save service manifest
    service_manifest = generate_service_manifest(variables)
    service_path = output_path / 'service.yaml'
    save_yaml_to_file(service_manifest, service_path)
    generated_files['service'] = service_path
    
    # Generate and save ingress manifest
    ingress_manifest = generate_ingress_manifest(variables)
    ingress_path = output_path / 'ingress.yaml'
    save_yaml_to_file(ingress_manifest, ingress_path)
    generated_files['ingress'] = ingress_path
    
    # Generate and save configmap manifest
    configmap_manifest = generate_configmap_manifest(variables)
    configmap_path = output_path / 'configmap.yaml'
    save_yaml_to_file(configmap_manifest, configmap_path)
    generated_files['configmap'] = configmap_path
    
    # Generate and save secret manifest
    secrets_manifest = generate_secrets_manifest(variables)
    secrets_path = output_path / 'secrets.yaml'
    save_yaml_to_file(secrets_manifest, secrets_path)
    generated_files['secrets'] = secrets_path
    
    # Generate and save hpa manifest
    hpa_manifest = generate_hpa_manifest(variables)
    hpa_path = output_path / 'hpa.yaml'
    save_yaml_to_file(hpa_manifest, hpa_path)
    generated_files['hpa'] = hpa_path
    
    return generated_files

class KubernetesDeploymentManager:
    """
    Manager class for handling Kubernetes deployment operations for the Amira Wellness backend.
    """
    
    def __init__(self, environment, variables, kubeconfig_path=None, namespace='amira'):
        """
        Initialize the KubernetesDeploymentManager.
        
        Args:
            environment (str): Environment (development, staging, production)
            variables (dict): Variables for template substitution
            kubeconfig_path (str, optional): Path to kubeconfig file. Defaults to None (use default kubeconfig).
            namespace (str, optional): Kubernetes namespace. Defaults to 'amira'.
        """
        self.environment = environment
        self.variables = variables
        self.namespace = namespace
        
        # Initialize Kubernetes API client
        if kubeconfig_path:
            kubernetes.config.load_kube_config(config_file=kubeconfig_path)
        else:
            try:
                kubernetes.config.load_kube_config()
            except kubernetes.config.config_exception.ConfigException:
                # Try in-cluster config if running inside a pod
                kubernetes.config.load_incluster_config()
        
        self.api_client = kubernetes.client.ApiClient()
        
        # Validate connection
        self.validate_kubernetes_connection()
    
    def validate_kubernetes_connection(self):
        """
        Validates that Kubernetes API connection is properly configured.
        
        Returns:
            bool: True if connection is valid, False otherwise
        """
        try:
            version_api = kubernetes.client.VersionApi(self.api_client)
            version_info = version_api.get_code()
            return True
        except Exception as e:
            print(f"Error connecting to Kubernetes: {e}")
            return False
    
    def generate_manifest_files(self, output_dir):
        """
        Generate Kubernetes manifest files for the specified environment.
        
        Args:
            output_dir (str): Directory to save the generated manifests
            
        Returns:
            dict: Dictionary of generated files and their paths
        """
        return generate_kubernetes_manifests(self.variables, output_dir)
    
    def apply_manifest(self, manifest):
        """
        Applies a Kubernetes manifest to the cluster.
        
        Args:
            manifest (dict): Kubernetes manifest to apply
            
        Returns:
            dict: Result of the apply operation
        """
        kind = manifest.get('kind', '').lower()
        api_version = manifest.get('apiVersion', '')
        metadata = manifest.get('metadata', {})
        name = metadata.get('name', '')
        
        if not all([kind, api_version, name]):
            return {
                'success': False,
                'error': 'Invalid manifest: missing kind, apiVersion, or name'
            }
        
        try:
            # Determine the API client to use based on the resource kind
            if kind == 'deployment':
                api_instance = kubernetes.client.AppsV1Api(self.api_client)
                
                # Check if the deployment already exists
                try:
                    existing = api_instance.read_namespaced_deployment(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing deployment
                    result = api_instance.replace_namespaced_deployment(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new deployment
                        result = api_instance.create_namespaced_deployment(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            elif kind == 'service':
                api_instance = kubernetes.client.CoreV1Api(self.api_client)
                
                # Check if the service already exists
                try:
                    existing = api_instance.read_namespaced_service(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing service
                    result = api_instance.replace_namespaced_service(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new service
                        result = api_instance.create_namespaced_service(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            elif kind == 'ingress':
                api_instance = kubernetes.client.NetworkingV1Api(self.api_client)
                
                # Check if the ingress already exists
                try:
                    existing = api_instance.read_namespaced_ingress(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing ingress
                    result = api_instance.replace_namespaced_ingress(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new ingress
                        result = api_instance.create_namespaced_ingress(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            elif kind == 'configmap':
                api_instance = kubernetes.client.CoreV1Api(self.api_client)
                
                # Check if the configmap already exists
                try:
                    existing = api_instance.read_namespaced_config_map(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing configmap
                    result = api_instance.replace_namespaced_config_map(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new configmap
                        result = api_instance.create_namespaced_config_map(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            elif kind == 'secret':
                api_instance = kubernetes.client.CoreV1Api(self.api_client)
                
                # Check if the secret already exists
                try:
                    existing = api_instance.read_namespaced_secret(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing secret
                    result = api_instance.replace_namespaced_secret(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new secret
                        result = api_instance.create_namespaced_secret(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            elif kind == 'horizontalpodautoscaler':
                api_instance = kubernetes.client.AutoscalingV2Api(self.api_client)
                
                # Check if the hpa already exists
                try:
                    existing = api_instance.read_namespaced_horizontal_pod_autoscaler(
                        name=name, 
                        namespace=self.namespace
                    )
                    # Update existing hpa
                    result = api_instance.replace_namespaced_horizontal_pod_autoscaler(
                        name=name,
                        namespace=self.namespace,
                        body=manifest
                    )
                    operation = 'updated'
                except kubernetes.client.exceptions.ApiException as e:
                    if e.status == 404:
                        # Create new hpa
                        result = api_instance.create_namespaced_horizontal_pod_autoscaler(
                            namespace=self.namespace,
                            body=manifest
                        )
                        operation = 'created'
                    else:
                        raise
            
            else:
                return {
                    'success': False,
                    'error': f'Unsupported resource kind: {kind}'
                }
            
            return {
                'success': True,
                'operation': operation,
                'kind': kind,
                'name': name,
                'namespace': self.namespace
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'kind': kind,
                'name': name,
                'namespace': self.namespace
            }
    
    def deploy_application(self):
        """
        Deploys the complete application to the Kubernetes cluster.
        
        Returns:
            dict: Deployment results with resource statuses
        """
        if not self.validate_kubernetes_connection():
            return {
                'success': False,
                'error': 'Failed to connect to Kubernetes cluster'
            }
        
        # Create temporary directory for manifests
        import tempfile
        temp_dir = tempfile.mkdtemp(prefix='amira-k8s-')
        
        try:
            # Generate manifest files
            manifests = self.generate_manifest_files(temp_dir)
            
            results = {
                'success': True,
                'resources': {}
            }
            
            # Apply configmap first
            configmap_path = manifests.get('configmap')
            if configmap_path:
                with open(configmap_path, 'r') as f:
                    configmap_manifest = yaml.safe_load(f)
                configmap_result = self.apply_manifest(configmap_manifest)
                results['resources']['configmap'] = configmap_result
                
                if not configmap_result.get('success'):
                    results['success'] = False
            
            # Apply secrets
            secrets_path = manifests.get('secrets')
            if secrets_path:
                with open(secrets_path, 'r') as f:
                    secrets_manifest = yaml.safe_load(f)
                secrets_result = self.apply_manifest(secrets_manifest)
                results['resources']['secrets'] = secrets_result
                
                if not secrets_result.get('success'):
                    results['success'] = False
            
            # Apply deployment
            deployment_path = manifests.get('deployment')
            if deployment_path:
                with open(deployment_path, 'r') as f:
                    deployment_manifest = yaml.safe_load(f)
                deployment_result = self.apply_manifest(deployment_manifest)
                results['resources']['deployment'] = deployment_result
                
                if not deployment_result.get('success'):
                    results['success'] = False
            
            # Apply service
            service_path = manifests.get('service')
            if service_path:
                with open(service_path, 'r') as f:
                    service_manifest = yaml.safe_load(f)
                service_result = self.apply_manifest(service_manifest)
                results['resources']['service'] = service_result
                
                if not service_result.get('success'):
                    results['success'] = False
            
            # Apply ingress
            ingress_path = manifests.get('ingress')
            if ingress_path:
                with open(ingress_path, 'r') as f:
                    ingress_manifest = yaml.safe_load(f)
                ingress_result = self.apply_manifest(ingress_manifest)
                results['resources']['ingress'] = ingress_result
                
                if not ingress_result.get('success'):
                    results['success'] = False
            
            # Apply hpa
            hpa_path = manifests.get('hpa')
            if hpa_path:
                with open(hpa_path, 'r') as f:
                    hpa_manifest = yaml.safe_load(f)
                hpa_result = self.apply_manifest(hpa_manifest)
                results['resources']['hpa'] = hpa_result
                
                if not hpa_result.get('success'):
                    results['success'] = False
            
            # Wait for deployment to be ready if it was successful
            if results['resources'].get('deployment', {}).get('success'):
                deployment_name = results['resources']['deployment']['name']
                ready = self.wait_for_deployment_ready(deployment_name, 300)
                results['deployment_ready'] = ready
            
            return results
        
        finally:
            # Clean up temporary files
            import shutil
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    def wait_for_deployment_ready(self, deployment_name, timeout_seconds=300):
        """
        Waits for a deployment to reach the ready state.
        
        Args:
            deployment_name (str): Name of the deployment
            timeout_seconds (int): Maximum time to wait in seconds
            
        Returns:
            bool: True if deployment is ready, False if timeout occurs
        """
        import time
        
        api_instance = kubernetes.client.AppsV1Api(self.api_client)
        start_time = time.time()
        
        while time.time() - start_time < timeout_seconds:
            try:
                deployment = api_instance.read_namespaced_deployment_status(
                    name=deployment_name,
                    namespace=self.namespace
                )
                
                # Check if deployment is ready
                if (deployment.status.ready_replicas is not None and
                    deployment.status.ready_replicas == deployment.status.replicas):
                    return True
                
                # Wait before checking again
                time.sleep(5)
            
            except kubernetes.client.exceptions.ApiException as e:
                # If deployment not found, return False
                if e.status == 404:
                    return False
                # For other errors, wait and retry
                time.sleep(5)
        
        # Timeout reached
        return False
    
    def get_deployment_status(self):
        """
        Gets the current status of deployed resources.
        
        Returns:
            dict: Status of all deployed resources
        """
        result = {
            'environment': self.environment,
            'namespace': self.namespace,
            'resources': {}
        }
        
        # Get deployment status
        apps_api = kubernetes.client.AppsV1Api(self.api_client)
        try:
            deployments = apps_api.list_namespaced_deployment(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            result['resources']['deployments'] = []
            for deployment in deployments.items:
                deployment_status = {
                    'name': deployment.metadata.name,
                    'replicas': deployment.status.replicas,
                    'ready_replicas': deployment.status.ready_replicas,
                    'available_replicas': deployment.status.available_replicas,
                    'unavailable_replicas': deployment.status.unavailable_replicas,
                    'updated_replicas': deployment.status.updated_replicas,
                    'images': [container.image for container in deployment.spec.template.spec.containers]
                }
                result['resources']['deployments'].append(deployment_status)
        except Exception as e:
            result['resources']['deployments'] = {'error': str(e)}
        
        # Get service status
        core_api = kubernetes.client.CoreV1Api(self.api_client)
        try:
            services = core_api.list_namespaced_service(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            result['resources']['services'] = []
            for service in services.items:
                service_status = {
                    'name': service.metadata.name,
                    'type': service.spec.type,
                    'cluster_ip': service.spec.cluster_ip,
                    'ports': [{'port': port.port, 'target_port': port.target_port, 'name': port.name}
                              for port in service.spec.ports]
                }
                result['resources']['services'].append(service_status)
        except Exception as e:
            result['resources']['services'] = {'error': str(e)}
        
        # Get ingress status
        networking_api = kubernetes.client.NetworkingV1Api(self.api_client)
        try:
            ingresses = networking_api.list_namespaced_ingress(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            result['resources']['ingresses'] = []
            for ingress in ingresses.items:
                ingress_status = {
                    'name': ingress.metadata.name,
                    'hosts': [rule.host for rule in ingress.spec.rules if rule.host],
                    'load_balancer': ingress.status.load_balancer.ingress if ingress.status.load_balancer else None
                }
                result['resources']['ingresses'].append(ingress_status)
        except Exception as e:
            result['resources']['ingresses'] = {'error': str(e)}
        
        # Get HPA status
        autoscaling_api = kubernetes.client.AutoscalingV2Api(self.api_client)
        try:
            hpas = autoscaling_api.list_namespaced_horizontal_pod_autoscaler(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            result['resources']['hpas'] = []
            for hpa in hpas.items:
                hpa_status = {
                    'name': hpa.metadata.name,
                    'target': f"{hpa.spec.scale_target_ref.kind}/{hpa.spec.scale_target_ref.name}",
                    'min_replicas': hpa.spec.min_replicas,
                    'max_replicas': hpa.spec.max_replicas,
                    'current_replicas': hpa.status.current_replicas,
                    'desired_replicas': hpa.status.desired_replicas,
                    'metrics': [
                        {
                            'type': metric.type,
                            'name': metric.resource.name if metric.resource else None,
                            'current_value': None  # Would need to extract from status
                        } for metric in hpa.spec.metrics
                    ] if hpa.spec.metrics else []
                }
                result['resources']['hpas'].append(hpa_status)
        except Exception as e:
            result['resources']['hpas'] = {'error': str(e)}
        
        return result
    
    def delete_resources(self, delete_all=False):
        """
        Deletes Kubernetes resources for a specific environment.
        
        Args:
            delete_all (bool): If True, also delete ConfigMap and Secret resources
            
        Returns:
            dict: Deletion results
        """
        result = {
            'success': True,
            'resources': {}
        }
        
        # Delete Ingress
        networking_api = kubernetes.client.NetworkingV1Api(self.api_client)
        try:
            ingresses = networking_api.list_namespaced_ingress(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            for ingress in ingresses.items:
                networking_api.delete_namespaced_ingress(
                    name=ingress.metadata.name,
                    namespace=self.namespace
                )
            
            result['resources']['ingresses'] = {
                'success': True,
                'count': len(ingresses.items)
            }
        except Exception as e:
            result['resources']['ingresses'] = {
                'success': False,
                'error': str(e)
            }
            result['success'] = False
        
        # Delete Service
        core_api = kubernetes.client.CoreV1Api(self.api_client)
        try:
            services = core_api.list_namespaced_service(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            for service in services.items:
                core_api.delete_namespaced_service(
                    name=service.metadata.name,
                    namespace=self.namespace
                )
            
            result['resources']['services'] = {
                'success': True,
                'count': len(services.items)
            }
        except Exception as e:
            result['resources']['services'] = {
                'success': False,
                'error': str(e)
            }
            result['success'] = False
        
        # Delete HPA
        autoscaling_api = kubernetes.client.AutoscalingV2Api(self.api_client)
        try:
            hpas = autoscaling_api.list_namespaced_horizontal_pod_autoscaler(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            for hpa in hpas.items:
                autoscaling_api.delete_namespaced_horizontal_pod_autoscaler(
                    name=hpa.metadata.name,
                    namespace=self.namespace
                )
            
            result['resources']['hpas'] = {
                'success': True,
                'count': len(hpas.items)
            }
        except Exception as e:
            result['resources']['hpas'] = {
                'success': False,
                'error': str(e)
            }
            result['success'] = False
        
        # Delete Deployment
        apps_api = kubernetes.client.AppsV1Api(self.api_client)
        try:
            deployments = apps_api.list_namespaced_deployment(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            for deployment in deployments.items:
                apps_api.delete_namespaced_deployment(
                    name=deployment.metadata.name,
                    namespace=self.namespace
                )
            
            result['resources']['deployments'] = {
                'success': True,
                'count': len(deployments.items)
            }
        except Exception as e:
            result['resources']['deployments'] = {
                'success': False,
                'error': str(e)
            }
            result['success'] = False
        
        # Delete ConfigMap and Secret if delete_all is True
        if delete_all:
            # Delete ConfigMap
            try:
                configmaps = core_api.list_namespaced_config_map(
                    namespace=self.namespace,
                    label_selector='app=amira-backend'
                )
                
                for configmap in configmaps.items:
                    core_api.delete_namespaced_config_map(
                        name=configmap.metadata.name,
                        namespace=self.namespace
                    )
                
                result['resources']['configmaps'] = {
                    'success': True,
                    'count': len(configmaps.items)
                }
            except Exception as e:
                result['resources']['configmaps'] = {
                    'success': False,
                    'error': str(e)
                }
                result['success'] = False
            
            # Delete Secret
            try:
                secrets = core_api.list_namespaced_secret(
                    namespace=self.namespace,
                    label_selector='app=amira-backend'
                )
                
                for secret in secrets.items:
                    core_api.delete_namespaced_secret(
                        name=secret.metadata.name,
                        namespace=self.namespace
                    )
                
                result['resources']['secrets'] = {
                    'success': True,
                    'count': len(secrets.items)
                }
            except Exception as e:
                result['resources']['secrets'] = {
                    'success': False,
                    'error': str(e)
                }
                result['success'] = False
        
        return result
    
    def update_deployment(self, image_tag=None, config_updates=None):
        """
        Updates an existing deployment with a new image or configuration.
        
        Args:
            image_tag (str, optional): New image tag to deploy. Defaults to None.
            config_updates (dict, optional): Configuration updates. Defaults to None.
            
        Returns:
            dict: Update result
        """
        apps_api = kubernetes.client.AppsV1Api(self.api_client)
        
        try:
            # Get current deployment
            deployments = apps_api.list_namespaced_deployment(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            if not deployments.items:
                return {
                    'success': False,
                    'error': 'No deployments found matching label app=amira-backend'
                }
            
            deployment = deployments.items[0]
            deployment_name = deployment.metadata.name
            
            # Update image if provided
            if image_tag:
                for container in deployment.spec.template.spec.containers:
                    if container.name == 'amira-backend':
                        # Extract repository URL from existing image
                        image_parts = container.image.split(':')
                        repository = image_parts[0]
                        container.image = f"{repository}:{image_tag}"
            
            # Update config if provided
            if config_updates:
                # This would be handled differently based on your config structure
                # For example, updating environment variables or config maps
                pass
            
            # Update the deployment
            updated_deployment = apps_api.replace_namespaced_deployment(
                name=deployment_name,
                namespace=self.namespace,
                body=deployment
            )
            
            # Wait for rollout to complete
            ready = self.wait_for_deployment_ready(deployment_name, 300)
            
            return {
                'success': True,
                'deployment_name': deployment_name,
                'image_updated': image_tag is not None,
                'config_updated': config_updates is not None,
                'ready': ready
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def rollback_deployment(self, revision=None):
        """
        Rolls back a deployment to a previous revision.
        
        Args:
            revision (int, optional): Specific revision to rollback to. Defaults to previous revision.
            
        Returns:
            dict: Rollback result
        """
        apps_api = kubernetes.client.AppsV1Api(self.api_client)
        
        try:
            # Get deployments
            deployments = apps_api.list_namespaced_deployment(
                namespace=self.namespace,
                label_selector='app=amira-backend'
            )
            
            if not deployments.items:
                return {
                    'success': False,
                    'error': 'No deployments found matching label app=amira-backend'
                }
            
            deployment_name = deployments.items[0].metadata.name
            
            # For K8s 1.22+, the rollback API is removed, so we'll simulate it with a patch
            if revision:
                # Get the specific revision from the deployment history
                # This would require accessing the ReplicaSet history which is beyond this example
                pass
            else:
                # Get the second-to-last ReplicaSet (previous revision)
                replica_sets = apps_api.list_namespaced_replica_set(
                    namespace=self.namespace,
                    label_selector=f"app=amira-backend"
                )
                
                # Sort by creation timestamp
                sorted_rs = sorted(
                    replica_sets.items, 
                    key=lambda rs: rs.metadata.creation_timestamp,
                    reverse=True
                )
                
                if len(sorted_rs) < 2:
                    return {
                        'success': False,
                        'error': 'No previous revision found for rollback'
                    }
                
                previous_rs = sorted_rs[1]
                
                # Extract the template spec from the previous ReplicaSet
                previous_template = previous_rs.spec.template
                
                # Update the deployment with the previous template
                deployment = deployments.items[0]
                deployment.spec.template = previous_template
                
                # Update the deployment
                updated_deployment = apps_api.replace_namespaced_deployment(
                    name=deployment_name,
                    namespace=self.namespace,
                    body=deployment
                )
            
            # Wait for rollback to complete
            ready = self.wait_for_deployment_ready(deployment_name, 300)
            
            return {
                'success': True,
                'deployment_name': deployment_name,
                'ready': ready
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_deployment_logs(self, deployment_name=None, tail_lines=100):
        """
        Gets logs from deployment pods.
        
        Args:
            deployment_name (str, optional): Name of the deployment. Defaults to first deployment found.
            tail_lines (int, optional): Number of lines to return. Defaults to 100.
            
        Returns:
            dict: Logs from deployment pods
        """
        core_api = kubernetes.client.CoreV1Api(self.api_client)
        apps_api = kubernetes.client.AppsV1Api(self.api_client)
        
        try:
            # Get deployment
            if deployment_name:
                deployment = apps_api.read_namespaced_deployment(
                    name=deployment_name,
                    namespace=self.namespace
                )
            else:
                deployments = apps_api.list_namespaced_deployment(
                    namespace=self.namespace,
                    label_selector='app=amira-backend'
                )
                
                if not deployments.items:
                    return {
                        'success': False,
                        'error': 'No deployments found matching label app=amira-backend'
                    }
                
                deployment = deployments.items[0]
                deployment_name = deployment.metadata.name
            
            # Get pod selector from deployment
            selector = deployment.spec.selector.match_labels
            selector_str = ','.join([f"{k}={v}" for k, v in selector.items()])
            
            # Get pods for the deployment
            pods = core_api.list_namespaced_pod(
                namespace=self.namespace,
                label_selector=selector_str
            )
            
            if not pods.items:
                return {
                    'success': False,
                    'error': f'No pods found for deployment {deployment_name}'
                }
            
            # Get logs for each pod
            logs = {}
            for pod in pods.items:
                pod_name = pod.metadata.name
                try:
                    pod_logs = core_api.read_namespaced_pod_log(
                        name=pod_name,
                        namespace=self.namespace,
                        container='amira-backend',  # assuming container name
                        tail_lines=tail_lines
                    )
                    logs[pod_name] = pod_logs
                except Exception as e:
                    logs[pod_name] = f"Error retrieving logs: {str(e)}"
            
            return {
                'success': True,
                'deployment_name': deployment_name,
                'pods': len(logs),
                'logs': logs
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }