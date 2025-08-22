# PowerShell script to generate RSA keys for Windows

# Create keys directory if it doesn't exist
if (!(Test-Path -Path "keys")) {
    New-Item -ItemType Directory -Path "keys"
}

# Check if OpenSSL is available
try {
    openssl version
    Write-Host "OpenSSL found, generating keys..."
    
    # Generate RSA private key (2048 bits)
    openssl genrsa -out keys/private.pem 2048
    
    # Generate RSA public key from private key
    openssl rsa -in keys/private.pem -pubout -out keys/public.pem
    
    Write-Host "RSA keys generated successfully!" -ForegroundColor Green
    Write-Host "Private key: keys/private.pem" -ForegroundColor Yellow
    Write-Host "Public key: keys/public.pem" -ForegroundColor Yellow
}
catch {
    Write-Host "OpenSSL not found. Please install OpenSSL or use the Docker setup which includes key generation." -ForegroundColor Red
    Write-Host "Alternative: Install OpenSSL from https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
}
