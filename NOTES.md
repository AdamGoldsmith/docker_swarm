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
VALUES
  ('Maxstoke', 1345, 253, 1066, 231),
  ('Kenilworth', 1120, 427, 5599, 438),
  ('Warwick', 1068, 2209, 6732, 758);
```

```sql
UPDATE `Keep` SET `Animals` = 999 WHERE `Name` = 'Maxstoke';
```

```sql
UPDATE `Keep` SET `Animals` = `Animals` + 1 WHERE `Name` = 'Maxstoke';
```

# TODO

* Consider using the `ansible_user` variable defined in `group_vars/all/vars.yml` as the source for the prepare_ansible_targets.sh template
* Couldn't get mysqldb to work with mysqli connection - character set issues. Mariadb works fine though :-)
