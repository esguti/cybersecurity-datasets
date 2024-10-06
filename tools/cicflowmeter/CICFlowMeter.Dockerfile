FROM maven:3.8.1-openjdk-8

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git parallel libpcap-dev gradle && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ahlashkari/CICFlowMeter.git

WORKDIR /CICFlowMeter/jnetpcap/linux/jnetpcap-1.4.r1425
RUN mvn install:install-file -Dfile=jnetpcap.jar -DgroupId=org.jnetpcap -DartifactId=jnetpcap -Dversion=1.4.1 -Dpackaging=jar

WORKDIR /CICFlowMeter
COPY ./build.gradle ./build.gradle
RUN gradle fatJarCMD

ENV LD_LIBRARY_PATH /CICFlowMeter/jnetpcap/linux/jnetpcap-1.4.r1425/

ENTRYPOINT ["java", "-Djava.library.path=/CICFlowMeter/jnetpcap/linux/jnetpcap-1.4.r1425/", "-jar", "build/libs/CICFlowMeter-4.0.jar"]


# usage:
# docker run -v filename.pcap:/tmp/filename.pcap -v /output/dir:/tmp/output/ --rm IMAGENAME /tmp/filename.pcap /tmp/output/

# you can extract the jar file from the container
# but make sure you have jnetpcap-lib installed
# docker run --rm --entrypoint cat cicimagename /CICFlowMeter/build/libs/CICFlowMeter-4.0.jar > CICFlowMeter.jar
