﻿using System.Diagnostics;
using System.Text.RegularExpressions;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace MX.Platform.MonitoringFunc;

public class ExternalHealthCheck
{
    private readonly IConfiguration configuration;
    private readonly TelemetryClient telemetryClient;
    public Dictionary<string, TelemetryClient> telemetryClients { get; set; } = new Dictionary<string, TelemetryClient>();

    public ExternalHealthCheck(IConfiguration configuration, TelemetryClient telemetryClient)
    {
        this.configuration = configuration;
        this.telemetryClient = telemetryClient;
    }

    [Function(nameof(ExternalHealthCheck))]
    public async Task Run([TimerTrigger("0 */5 * * * *")] TimerInfo timer, ILogger log, FunctionContext executionContext)
    {
        var testConfigs = JsonConvert.DeserializeObject<List<TestConfig>>(configuration["test_config"]);

        foreach (var testConfig in testConfigs)
        {
            if (!telemetryClients.ContainsKey(testConfig.AppInsights))
            {
                var telemetryConfiguration = new TelemetryConfiguration
                {
                    ConnectionString = configuration[$"{testConfig.AppInsights.ToLower()}_appinsights_connection_string"],
                    TelemetryChannel = new InMemoryChannel()
                };
                telemetryClients.Add(testConfig.AppInsights, new TelemetryClient(telemetryConfiguration));
            }

            var telemetryClient = telemetryClients[testConfig.AppInsights];
            string location = Environment.GetEnvironmentVariable("REGION_NAME") ?? "Unknown";

            var availability = new AvailabilityTelemetry
            {
                Name = testConfig.App,
                RunLocation = location,
                Success = false,
            };

            availability.Context.Operation.ParentId = Activity.Current.SpanId.ToString();
            availability.Context.Operation.Id = Activity.Current.RootId;
            var stopwatch = new Stopwatch();
            stopwatch.Start();

            try
            {
                using (var activity = new Activity("AvailabilityContext"))
                {
                    activity.Start();
                    availability.Id = Activity.Current.SpanId.ToString();
                    // Run business logic 
                    await RunAvailabilityTestAsync(log, testConfig.Uri);
                }
                availability.Success = true;
            }
            catch (Exception ex)
            {
                availability.Message = ex.Message;
            }
            finally
            {
                stopwatch.Stop();
                availability.Duration = stopwatch.Elapsed;
                availability.Timestamp = DateTimeOffset.UtcNow;
                telemetryClient.TrackAvailability(availability);
                telemetryClient.Flush();
            }

        }
    }

    private async Task RunAvailabilityTestAsync(ILogger log, string uri)
    {
        var match = Regex.Match(uri, @"{([^}]+)}");
        if (match.Success)
        {
            foreach (var token in match.Groups)
            {
                var tokenKey = token.ToString();
                if (tokenKey == null) continue;

                if (configuration[tokenKey] == null)
                {
                    telemetryClient.TrackException(new Exception($"Token {token} not found in configuration"));
                    continue;
                }

                uri = uri.Replace(string.Format("{{0}}", token), configuration[tokenKey]);
            }
        }

        // Create a new HttpClient and send a request to the configured URI and validate that the response is a 200 OK, otherwise throw an exception
        using (var httpClient = new HttpClient())
        {
            var response = await httpClient.GetAsync(uri);
            if (!response.IsSuccessStatusCode)
            {
                telemetryClient.TrackTrace(response.Content.ReadAsStringAsync().Result);
                throw new Exception($"Failed to get a successful response from {uri}, received {response.StatusCode}");
            }
        }
    }
}
