import os  # builtin
import pathlib  # builtin
import typing  # builtin
import enum  # builtin
import yaml  # pyyaml version: 6.0
import json  # builtin

# Internal imports
from .aws import AWSDeploymentManager, AWSResourceFactory  # Import AWS deployment utilities
from .kubernetes import KubernetesDeploymentManager, generate_kubernetes_manifests  # Import Kubernetes deployment utilities

# Define global variables
DEPLOY_DIR = pathlib.Path(__file__).parent.absolute()
__version__ = "0.1.0"


def load_config(config_path: pathlib.Path) -> dict:
    """Loads deployment configuration from a YAML or JSON file

    Args:
        config_path (pathlib.Path): Path to the configuration file

    Returns:
        dict: The configuration as a Python dictionary
    """
    # Determine file type from extension
    if config_path.suffix in ['.yaml', '.yml']:
        file_type = 'yaml'
    elif config_path.suffix == '.json':
        file_type = 'json'
    else:
        raise ValueError("Unsupported configuration file type. Use YAML or JSON.")

    # Open the file for reading
    with open(config_path, 'r') as f:
        # Parse the file content based on type
        if file_type == 'yaml':
            config = yaml.safe_load(f)
        else:  # file_type == 'json'
            config = json.load(f)

    # Return the parsed configuration dictionary
    return config


def save_config(config: dict, config_path: pathlib.Path) -> pathlib.Path:
    """Saves deployment configuration to a YAML or JSON file

    Args:
        config (dict): Configuration dictionary to save
        config_path (pathlib.Path): Path to save the configuration file

    Returns:
        pathlib.Path: Path to the saved file
    """
    # Determine file type from extension
    if config_path.suffix in ['.yaml', '.yml']:
        file_type = 'yaml'
    elif config_path.suffix == '.json':
        file_type = 'json'
    else:
        raise ValueError("Unsupported configuration file type. Use YAML or JSON.")

    # Create parent directories if they don't exist
    config_path.parent.mkdir(parents=True, exist_ok=True)

    # Open the file for writing
    with open(config_path, 'w') as f:
        # Write the configuration based on type
        if file_type == 'yaml':
            yaml.dump(config, f, indent=2)
        else:  # file_type == 'json'
            json.dump(config, f, indent=4)

    # Return the file path
    return config_path


def get_environment_variables(environment: str, config_path: pathlib.Path = None) -> dict:
    """Gets environment-specific variables from environment variables or config file

    Args:
        environment (str): The deployment environment (development, staging, production)
        config_path (pathlib.Path, optional): Path to the configuration file. Defaults to None.

    Returns:
        dict: Dictionary of environment-specific variables
    """
    # Load configuration from file if provided
    config = load_config(config_path) if config_path else {}

    # Get environment variables from OS environment
    env_vars = dict(os.environ)

    # Merge configuration and environment variables, with environment variables taking precedence
    variables = config.copy()
    variables.update(env_vars)

    # Apply environment-specific overrides
    env_overrides = variables.get(environment, {})
    variables.update(env_overrides)

    # Return the combined variables dictionary
    return variables


def create_deployment_manager(target: 'DeploymentTarget', environment: str, variables: dict, options: dict) -> typing.Union[AWSDeploymentManager, KubernetesDeploymentManager]:
    """Creates a deployment manager for the specified target and environment

    Args:
        target (DeploymentTarget): The deployment target (AWS or Kubernetes)
        environment (str): The deployment environment (development, staging, production)
        variables (dict): Dictionary of variables to use for deployment
        options (dict): Additional deployment options

    Returns:
        Union[AWSDeploymentManager, KubernetesDeploymentManager]: The appropriate deployment manager instance
    """
    # Check the deployment target type
    if target == DeploymentTarget.AWS:
        # Create and return an AWSDeploymentManager instance
        return AWSDeploymentManager(environment=environment, variables=variables)
    elif target == DeploymentTarget.KUBERNETES:
        # Create and return a KubernetesDeploymentManager instance
        kubeconfig_path = options.get('kubeconfig_path')
        namespace = options.get('namespace', 'amira')
        return KubernetesDeploymentManager(environment=environment, variables=variables, kubeconfig_path=kubeconfig_path, namespace=namespace)
    else:
        # Raise ValueError for unsupported deployment targets
        raise ValueError(f"Unsupported deployment target: {target}")


def generate_deployment_files(target: 'DeploymentTarget', environment: str, variables: dict, output_dir: str) -> dict:
    """Generates deployment files for the specified target and environment

    Args:
        target (DeploymentTarget): The deployment target (AWS or Kubernetes)
        environment (str): The deployment environment (development, staging, production)
        variables (dict): Dictionary of variables to use for deployment
        output_dir (str): Directory to save the generated files

    Returns:
        dict: Dictionary of generated files and their paths
    """
    # Create the deployment manager for the specified target and environment
    deployment_manager = create_deployment_manager(target, environment, variables, {})

    # Generate deployment files using the manager
    generated_files = deployment_manager.generate_manifest_files(output_dir)

    # Return the dictionary of generated files
    return generated_files


def deploy_application(target: 'DeploymentTarget', environment: str, variables: dict, options: dict) -> dict:
    """Deploys the application to the specified target and environment

    Args:
        target (DeploymentTarget): The deployment target (AWS or Kubernetes)
        environment (str): The deployment environment (development, staging, production)
        variables (dict): Dictionary of variables to use for deployment
        options (dict): Additional deployment options

    Returns:
        dict: Deployment results with resource statuses
    """
    # Create the deployment manager for the specified target and environment
    deployment_manager = create_deployment_manager(target, environment, variables, options)

    # Deploy the application using the manager
    deployment_results = deployment_manager.deploy_application()

    # Return the deployment results
    return deployment_results


def get_deployment_status(target: 'DeploymentTarget', environment: str, options: dict) -> dict:
    """Gets the current status of deployed resources

    Args:
        target (DeploymentTarget): The deployment target (AWS or Kubernetes)
        environment (str): The deployment environment (development, staging, production)
        options (dict): Additional deployment options

    Returns:
        dict: Status of all deployed resources
    """
    # Create the deployment manager for the specified target and environment
    deployment_manager = create_deployment_manager(target, environment, {}, options)

    # Get deployment status using the manager
    status_information = deployment_manager.get_deployment_status()

    # Return the status information
    return status_information


def cleanup_resources(target: 'DeploymentTarget', environment: str, force_deletion: bool, options: dict) -> dict:
    """Cleans up deployed resources for a specific environment

    Args:
        target (DeploymentTarget): The deployment target (AWS or Kubernetes)
        environment (str): The deployment environment (development, staging, production)
        force_deletion (bool): Whether to force deletion without confirmation
        options (dict): Additional deployment options

    Returns:
        dict: Cleanup results
    """
    # Create the deployment manager for the specified target and environment
    deployment_manager = create_deployment_manager(target, environment, {}, options)

    # Clean up resources using the manager
    cleanup_results = deployment_manager.delete_resources(force_deletion)

    # Return the cleanup results
    return cleanup_results


class DeploymentTarget(enum.Enum):
    """Enumeration of supported deployment targets"""
    AWS = "aws"
    KUBERNETES = "kubernetes"


class DeploymentManager:
    """Base class for deployment managers with common functionality"""

    def __init__(self, environment: str, variables: dict):
        """Initialize the DeploymentManager

        Args:
            environment (str): Environment (development, staging, production)
            variables (dict): Variables for template substitution
        """
        # Set the environment (development, staging, production)
        self.environment = environment
        # Set the variables dictionary for template substitution
        self.variables = variables
        # Validate the environment value
        self.validate_environment()

    def validate_environment(self) -> bool:
        """Validates that the environment is one of the supported values

        Returns:
            bool: True if environment is valid, False otherwise
        """
        # Check if environment is one of 'development', 'staging', or 'production'
        if self.environment not in ['development', 'staging', 'production']:
            # Raise ValueError if invalid
            raise ValueError(f"Invalid environment: {self.environment}. Must be one of 'development', 'staging', or 'production'.")
        # Return True if valid
        return True

    def generate_deployment_files(self, output_dir: str) -> dict:
        """Abstract method to generate deployment files

        Args:
            output_dir (str): Directory to save the generated files

        Returns:
            dict: Dictionary of generated files and their paths
        """
        # This is an abstract method that should be implemented by subclasses
        raise NotImplementedError

    def deploy(self) -> dict:
        """Abstract method to deploy the application

        Returns:
            dict: Deployment results
        """
        # This is an abstract method that should be implemented by subclasses
        raise NotImplementedError

    def get_status(self) -> dict:
        """Abstract method to get deployment status

        Returns:
            dict: Status information
        """
        # This is an abstract method that should be implemented by subclasses
        raise NotImplementedError

    def cleanup(self, force_deletion: bool) -> dict:
        """Abstract method to clean up resources

        Args:
            force_deletion (bool): Whether to force deletion

        Returns:
            dict: Cleanup results
        """
        # This is an abstract method that should be implemented by subclasses
        raise NotImplementedError