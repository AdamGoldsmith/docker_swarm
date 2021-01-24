# References

https://sysadmins.co.za/create-a-docker-persistent-mysql-service-backed-by-nfs/

# SQL demo data

```sql
create DATABASE Castle;
USE Castle;
create TABLE Keep (
    Name varchar(255),
    Year int,
    Population int,
    Food int,
    Animals int
);
INSERT INTO Keep
VALUES ('Maxstoke', 1345, 253, 1066, 231);
```

```sql
UPDATE `Keep` SET `Animals` = 789;
```

# TODO

* Consider using the `ansible_user` variable defined in `group_vars/all/vars.yml` as the source for the prepare_ansible_targets.sh template
* Couldn't get mysqldb to work with mysqli connection - character set issues. Mariadb works fine though :-)

