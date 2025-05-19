# Heroku Buildpack for AppSignal Collector

This buildpack automatically installs and configures the [AppSignal](https://appsignal.com) collector for your Heroku applications. The AppSignal collector is a lightweight agent that collects metrics and sends them to AppSignal's monitoring platform.

## Features

- 🚀 Automatic installation and configuration of the AppSignal collector
- 🔄 Automatic startup with your application

## Requirements

- Heroku-22 stack (Ubuntu 22.04)
- A valid AppSignal account and API key
- Your application deployed on Heroku

## Configuration

The buildpack requires the following environment variables to be set in your Heroku app:

### Required Variables

- `APPSIGNAL_PUSH_API_KEY`: Your AppSignal push API key
  - Find this in your AppSignal dashboard under "Push & Deploy"

## How It Works

1. **Detection**: The buildpack detects your application during the build phase
2. **Dependencies**: Installs required system dependencies (curl and gpg)
3. **Repository Setup**: Adds the official AppSignal repository and GPG key for Ubuntu 22.04
4. **Installation**: Installs the AppSignal collector package
5. **Configuration**: Sets up the collector with your API key and settings
6. **Startup**: Creates a profile.d script to ensure the collector starts automatically
7. **Monitoring**: The collector runs in the background, collecting and sending metrics

## Troubleshooting

### Common Issues

1. **Collector Not Starting**
   - Check if the buildpack is properly installed: `heroku buildpacks --app <app name>`
   - Verify your API key is set: `heroku config --app <app name> | grep APPSIGNAL`
   - Check the logs: `heroku logs --app <app name> --tail`

2. **Metrics Not Showing Up**
   - Ensure your API key is correct
   - Check if the collector is running: `heroku run --app <app name> ps aux | grep appsignal`
   - Verify network connectivity from your dyno

3. **Buildpack Installation Fails**
   - Ensure you're using the Heroku-22 stack
   - Check if you have the correct buildpack URL
   - Verify your app's buildpack order

## Development

### Testing

To run the test suite:

```bash
make test
```

To clean up test artifacts:

```bash
make clean
```

## Links

- [AppSignal Documentation](https://docs.appsignal.com)
- [Heroku Buildpacks Documentation](https://devcenter.heroku.com/articles/buildpacks)
- [Herolu Buildpack API Documentation](https://devcenter.heroku.com/articles/buildpack-api)
- [AppSignal Collector Documentation](https://docs.appsignal.com/collector)
