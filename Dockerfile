FROM oraclelinux:latest
RUN yum install -y deltarpm
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["download"]
