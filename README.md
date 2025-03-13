# Docker Compose Best Practices Examples for Different Tech Stacks

This repository provides a collection of well-structured Docker Compose examples, showcasing **best practices** for setting up and managing applications with various tech stacks.

The goal of this repository is to offer practical and easy-to-follow guidance for developers looking to use Docker Compose effectively and according to best practices in their projects.

## Table of Contents

- [Purpose](#purpose)
- [Supported Tech Stacks](#supported-tech-stacks)
- [Best Practices Demonstrated](#best-practices-demonstrated)
- [Usage Guide](#usage-guide)
- [Contributing](#contributing)
- [License](#license)

## Purpose

* **Demonstrate Best Practices:** Provide exemplary Docker Compose configurations that showcase crucial best practices in configuring and managing multi-container applications.
* **Practical Guidance:** Each tech stack example comes with detailed instructions, making it easy for users to understand and apply them to real-world projects.
* **Extensibility and Diversity:** The repository is designed to be easily extended, adding examples for various tech stacks, reflecting the diversity in modern application development.
* **Learning and Reference:** Serve as a valuable reference resource for the software development community to learn and effectively apply Docker Compose.

## Supported Tech Stacks

Currently, the repository includes examples for the following tech stacks:

* **[SonarQube and PostgreSQL](sonarqube/)**: SonarQube setup with PostgreSQL for code analysis and quality management.
* **[Prometheus and Grafana](prometheus-grafana/)**: Monitoring stack with Prometheus for metrics collection and Grafana for visualization.

**More tech stacks will be added in the future.** We aim to expand this list to include various programming languages, frameworks, databases, and other popular technologies.

## Best Practices Demonstrated

The examples in this repository demonstrate the following best practices:

* **Clear Docker Compose File Structure:** Utilize `docker-compose.yml` in a coherent, readable, and maintainable manner, logically dividing services.
* **Use of Environment Variables:** Employ environment variables to configure applications and services flexibly, avoiding hardcoding configuration values.
* **Effective Volume Management:** Utilize volumes for persistent data and mount code into containers for hot-reloading during development.
* **Networking Between Containers:** Establish networks for containers to communicate with each other securely and efficiently.
* **Optimized Dockerfile:** Build Dockerfiles following best practices to create lean, secure, and high-performance images.
* **Health Checks:** Configure health checks for services so Docker Compose can monitor their status and automatically restart when needed.

## Usage Guide

To use the examples in this repository:

1. **Clone the Repository:**
```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd docker_compose_example
```

2. **Choose Your Tech Stack:** Navigate into the directory of the tech stack you are interested in (e.g., `cd sonarqube` or `cd prometheus-grafana`).

3. **Start with Docker Compose:**
```bash
docker compose up --build
```

Refer to the `README.md` within each tech stack directory for detailed instructions on running and usage.

## Contributing

We welcome all contributions to make this repository richer and more helpful! If you would like to contribute:

* **Add New Tech Stack Examples:** You can suggest and contribute Docker Compose examples for other tech stacks.
* **Improve Existing Examples:** If you have ideas to improve existing examples regarding structure, best practices, or documentation.
* **Bug Fixes and Documentation Improvements:** Report bugs or suggest improvements for `README.md` and other documentation.

To contribute, please:

1. Fork this repository
2. Create a branch for your feature or fix (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## License

[MIT License](https://opensource.org/licenses/MIT)

---

**Note:**
* This repository is in its early development phase. We will continuously add more tech stack examples and refine the documentation.
* The goal is to build a high-quality collection of Docker Compose examples, focusing on best practices and practicality.
* All contributions and feedback from the community are highly appreciated!