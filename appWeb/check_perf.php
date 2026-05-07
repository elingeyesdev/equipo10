<?php
require 'appWeb/vendor/autoload.php';
$app = require_once 'appWeb/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$request = Illuminate\Http\Request::create('/api/cuadrantes', 'GET');
$start = microtime(true);
$response = $kernel->handle($request);
$end = microtime(true);

echo "Response Time: " . ($end - $start) . "s\n";
echo "Response Size: " . strlen($response->getContent()) . " bytes\n";
