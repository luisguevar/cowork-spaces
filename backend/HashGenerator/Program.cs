var hash = BCrypt.Net.BCrypt.HashPassword("12345678");
Console.WriteLine($"Hash: {hash}");
Console.WriteLine($"Verify: {BCrypt.Net.BCrypt.Verify("12345678", hash)}");