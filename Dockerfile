FROM tomcat:9.0.100-jre17
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ./target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]