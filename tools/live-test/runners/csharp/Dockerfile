FROM mcr.microsoft.com/dotnet/sdk:8.0

WORKDIR /smoke
COPY Smoke.csproj Program.cs JavaScriptSerializer.cs ./
COPY entrypoint.sh /smoke/entrypoint.sh
RUN chmod +x /smoke/entrypoint.sh
ENTRYPOINT ["/smoke/entrypoint.sh"]
