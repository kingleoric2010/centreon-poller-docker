FROM centos:centos6
MAINTAINER marek.knappe <marek@ecconnect.com.au>

# Update CentOS
RUN yum -y update

# Install ssh
RUN yum -y install openssh-server openssh-client openssh-clients
RUN mkdir /var/run/sshd
RUN sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
RUN /etc/init.d/sshd start && /etc/init.d/sshd stop

# Install centreon
RUN yum -y install python-setuptools

RUN yum -y install http://yum.centreon.com/standard/3.0/stable/noarch/RPMS/ces-release-3.0-1.noarch.rpm

RUN yum -y install centreon-engine centreon-broker-cbmod nagios-plugins centreon-plugins centreon-plugin-meta 


# Set rights for setuid
RUN chown root:centreon-engine /usr/lib/nagios/plugins/check_icmp
RUN chmod -w /usr/lib/nagios/plugins/check_icmp
RUN chmod u+s /usr/lib/nagios/plugins/check_icmp
RUN chown apache.centreon-engine /etc/centreon-engine -R
RUN chown apache.centreon-broker /etc/centreon-broker -R
RUN chown centreon.centreon /etc/centreon-engine/ -R
RUN chown centreon-engine.centreon-engine /var/log/centreon-broker/
RUN usermod -G centreon-engine centreon-broker
RUN usermod -G centreon-broker centreon-engine
RUN mkdir /var/lib/centreon-broker_tmp/ && chown centreon-broker.centreon-broker /var/lib/centreon-broker_tmp/ && chmod g+w /var/lib/centreon-broker_tmp/
RUN touch /var/log/centreon-engine/retention.dat && chown centreon-engine.centreon-engine /var/log/centreon-engine/retention.dat

#adding proper key to centron user
RUN mkdir /var/spool/centreon/.ssh
ADD scripts/centreon_authorized_keys /var/spool/centreon/.ssh/authorized_keys
RUN chmod 700 /var/spool/centreon/.ssh
RUN chmod go-w /var/spool/centreon/.ssh
RUN chmod 600 /var/spool/centreon/.ssh/authorized_keys
RUN chown centreon.centreon /var/spool/centreon/.ssh
RUN chown centreon.centreon /var/spool/centreon/.ssh/authorized_keys



#changing restarting of the centengine as it's run from supervisord not normal init.d script
RUN sed -i 's/service_restart$/killall -9 centengine/' /etc/init.d/centengine 

RUN easy_install supervisor

ADD scripts/supervisord.conf /etc/supervisord.conf



EXPOSE 22


#adding new sudoers to the centron file
ADD scripts/sudoers.new /tmp/sudoers.new
RUN cat /tmp/sudoers.new >> /etc/sudoers.d/centreon && rm /tmp/sudoers.new


CMD /usr/bin/supervisord --configuration=/etc/supervisord.conf
