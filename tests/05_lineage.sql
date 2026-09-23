select *
from table(pkg_lineage.downstream('STG_TRANSACTION',10))
order by dependency_depth,object_name;

select *
from table(pkg_lineage.upstream('PKG_DWH_LOAD',10))
order by dependency_depth,object_name;
