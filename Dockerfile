FROM ubuntu:22.04
LABEL maintainer Mark <chumheramis@gmail.com>

# Update package list and install dependencies
RUN apt-get update
RUN apt-get install -y wget
RUN DEBIAN_FRONTEND=noninteractive apt install -y postgresql

# Download and install Orthanc assets
RUN wget https://orthanc.uclouvain.be/downloads/linux-standard-base/orthanc/1.12.3/Orthanc -O /usr/local/sbin/Orthanc

RUN chmod +x /usr/local/sbin/Orthanc
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

# Create 'orthanc' user and group
RUN groupadd -r orthanc && useradd -r -g orthanc orthanc

# Set ownership of /OrthancStorage to orthanc:orthanc
RUN chown -R orthanc:orthanc /OrthancStorage

# Copy Configuration files
COPY ./config/* /etc/orthanc/
# Copy Plugin files
COPY ./plugins/* /usr/share/orthanc/plugins/

# Expose Orthanc's DICOM port
EXPOSE 4242
# Expose Orthanc's HTTP port
EXPOSE 8042

# Execute bash
CMD bash -c \
    # Start PostgreSQL Service
    "service postgresql start && \
    # Start Orthanc Service
    /usr/local/sbin/Orthanc /etc/orthanc/"
