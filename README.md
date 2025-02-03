## Atlant
Atlant is static web server that reads working directory files at the start. Uses hash table for fixed time access.

## Build
```
dub build
```

## Run
```
./atlant -p 8080 -w /var/www/html -x index.html -o http_bind=127.0.0.1 -o directory_list=yes
```