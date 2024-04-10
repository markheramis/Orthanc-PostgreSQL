FROM ubuntu:22.04
LABEL maintainer Mark <chumheramis@gmail.com>

# Update package list and install Orthanc and its plugins
RUN apt-get update
RUN apt install -y orthanc \
    orthanc-postgresql \
    orthanc-dicomweb
RUN apt install -y postgresql

# Set environment variables for PostgreSQL
ENV DB_USER=orthanc
ENV DB_PASS=orthanc
ENV DB_NAME=orthanc

# Initialize PostgreSQL
USER postgres

# Start PostgreSQL service
RUN /etc/init.d/postgresql start && \
    # Create PostgreSQL Role
    psql --command "CREATE USER ${DB_USER} WITH SUPERUSER PASSWORD '${DB_PASS}';" &&\
    # Create PostgreSQL Database
    createdb -O ${DB_USER} ${DB_NAME}

# Switch back to the root user
USER root

# Create /OrthancStorage folder 
RUN mkdir -p /OrthancStorage
# Set ownership of /OrthancStorage to orthanc:orthanc
RUN chown -R orthanc:orthanc /OrthancStorage

# Copy Configuration files
COPY ./config/orthanc.json /etc/orthanc/orthanc.json
COPY ./config/dicomweb.json /etc/orthanc/dicomweb.json
COPY ./config/postgresql.json /etc/orthanc/postgresql.json
COPY ./config/worklists.json /etc/orthanc/worklists.json
COPY ./config/credentials.json /etc/orthanc/credentials.json

# Expose Orthanc's DICOM port
EXPOSE 4242
# Expose Orthanc's HTTP port
EXPOSE 8042

# Execute bash
CMD bash -c \
    # Start PostgreSQL Service
    "service postgresql start && \
    # Start Orthanc Service
    service orthanc start && \
    # Show the log file
    tail -F /var/log/orthanc/Orthanc.log"
