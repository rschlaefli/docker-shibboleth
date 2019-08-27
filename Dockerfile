FROM centos/httpd-24-centos7

# switch to root for package installations
USER 0

# install httpd and shibboleth dependencies
RUN yum update -y \
  && yum install -y wget \
  && wget http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo -P /etc/yum.repos.d \
  && yum install -y shibboleth-3.0.4-3.2 \
  %% yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
  && yum-config-manager --enable remi-php72 \
  && yum update \
  && yum install -y php72 php72-php-fpm php72-php-gd php72-php-json php72-php-mbstring \
  && yum clean all -y \
  && rm -rf /var/cache/yum

# Shibboleth cannot use system libcurl on centos cf. https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPLinuxRH6
ENV LD_PRELOAD=/opt/shibboleth/lib64/libcurl.so.4

# set file and folder permissions
RUN chown -R 1001:root /etc/httpd/conf \
  && chmod -R g+rw /etc/httpd/conf \
  && chown -R 1001:root /etc/httpd/conf.d \
  && chmod -R g+rw /etc/httpd/conf.d \
  && chown -R 1001:root /var/run/httpd \
  && chmod -R g+rw /var/run/httpd \
  && chown -R 1001:root /etc/shibboleth \
  && chmod -R g+r /etc/shibboleth \
  && mkdir -p /var/run/shibboleth \
  && chown -R 1001:root /var/run/shibboleth \
  && chmod g+rw /var/run/shibboleth \
  && chown -R 1001:root /var/cache/shibboleth \
  && chmod g+rw /var/cache/shibboleth \
  && chown -R 1001:root /var/log/shibboleth \
  && chmod -R g+rw /var/log/shibboleth \
  && ln -sf /dev/stdout /var/log/shibboleth/shibd.log

# switch to an unprivileged user
USER 1001

# configure shibboleth logging
RUN sed -i 's|var/log/shibboleth.*|/proc/self/fd/1|' /etc/shibboleth/shibd.logger

# expose an unprivileged port
EXPOSE 8080

CMD ["/usr/sbin/shibd", "-F", "-f", "-w 30"]
