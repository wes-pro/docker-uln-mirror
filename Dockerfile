FROM oraclelinux:latest
RUN yum install -y createrepo
COPY entrypoint.sh /
COPY repo_list /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["download"]
