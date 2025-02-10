# AWS Billing Analysis Tool

## Overview

This application automates AWS cost management by fetching, analyzing, and visualizing billing information for the past 12 months. The tool provides comprehensive insights into cloud resource expenditure, helping organizations optimize their AWS spending.

## Prerequisites

### System Requirements
- Elixir
- Phoenix Framework
- AWS Account with Billing API access

### Environment Variables

Before running the application, configure the following environment variables:

- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_DEFAULT_REGION`: Your default AWS region (e.g., us-east-1)

**Note**: Ensure these credentials have appropriate permissions to access AWS Billing APIs.

## Installation

1. Clone the repository
```bash
git clone [repository-url]
cd [project-directory]
```

2. Install dependencies
```bash
mix setup
```

3. Set environment variables
   - On Unix/Linux: `export AWS_ACCESS_KEY_ID=your_key`
   - On Windows: `set AWS_ACCESS_KEY_ID=your_key`

## Running the Application

Start the Phoenix server:
```bash
mix phx.server
```

The application will be available at `http://localhost:4000`

## Features

- Automated AWS billing data retrieval
- Comprehensive cost analysis
- Interactive dashboard
- Detailed PDF report generation
- Flexible data filtering and visualization

## Screenshots

![Dashboard Overview](screenshots/dashboard.png)
*Main Dashboard Showing Cost Trends*

![Detailed Report](screenshots/detailed-report.png)
*Detailed Billing Report Visualization*

## Security Considerations

- API credentials are managed through environment variables
- Sensitive billing information is handled securely
- Implements error handling and circuit breaker patterns

## Troubleshooting

- Verify AWS credentials have correct permissions
- Check network connectivity
- Review error logs for detailed diagnostics

## Contributing

Please read `CONTRIBUTING.md` for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the [Your License] - see the `LICENSE.md` file for details.