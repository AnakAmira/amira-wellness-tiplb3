# src/backend/setup.py
import io
import os

from setuptools import find_packages, setup  # setuptools: latest

# Library description
here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()


def get_requirements():
    """Reads requirements from requirements.txt file"""
    with open("requirements.txt", "r") as f:
        requirements = f.readlines()
    requirements = [req.strip() for req in requirements if req.strip() and not req.startswith("#")]
    return requirements


setup_kwargs = {
    'name': 'amira-wellness',
    'version': '0.1.0',
    'description': 'Amira Wellness backend application for emotional well-being through voice journaling and self-regulation tools',
    'long_description': long_description,
    'long_description_content_type': 'text/markdown',
    'author': 'Amira Wellness Team',
    'author_email': 'dev@amirawellness.com',
    'url': 'https://github.com/amirawellness/backend',
    'packages': find_packages(exclude=['tests*', 'docs']),
    'include_package_data': True,
    'python_requires': '>=3.11',
    'install_requires': get_requirements(),
    'entry_points': {
        'console_scripts': [
            'amira-backend=main:main',
        ],
    },
    'classifiers': [
        'Development Status :: 4 - Beta',
        'Environment :: Web Environment',
        'Framework :: FastAPI',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.11',
        'Topic :: Internet :: WWW/HTTP',
        'Topic :: Software Development :: Libraries :: Application Frameworks',
    ],
    'zip_safe': False,
}

setup(**setup_kwargs)