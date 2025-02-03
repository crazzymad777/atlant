## Atlant
Atlant is static web server that reads working directory files at the start. Uses hash table for fixed time access.

## Search file Complexity
Runtime complexity: approximately O(1)
Memory complexity: O(N) without files stored in cache

## Build
```
dub build
```

## Run
```
./atlant -p 8080 -w /var/www/html -x index.html -o http_bind=127.0.0.1 -o directory_list=yes
```
