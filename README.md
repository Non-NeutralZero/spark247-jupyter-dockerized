# Componenents
|Package|Version|  
|:-----:|:-----:|  
| Python | 3 |
| JAVA openjdk | 8 |
| Spark | 2.4.7 |
| Anaconda | 2019.10 |


# Docker commands
```shell
docker build --tag spark247-jupyter . 
docker run -t -d -p 8889:8889 spark247-jupyter:latest
```
