select deptno, job, count(*), sum(sal)
from emp
group by rollup(deptno, job);