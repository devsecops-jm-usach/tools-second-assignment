# Use the official .NET 8.0 SDK image as the build environment
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the application and build
COPY . ./
RUN dotnet publish -c Release -o out

# Use the official .NET 8.0 runtime image for the final stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/out ./

# Expose the port your app runs on
EXPOSE 5000

# Set the entry point
ENTRYPOINT ["dotnet", "BrokenAuthDemo.dll"]