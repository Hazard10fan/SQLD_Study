-- ===================================================
-- ? 5월 27일 (수) - SQLD 실습 1일차
-- ===================================================

-- [실습 1] ROLLUP 함수 (부서별 중간 합계 + 전체 총합계)
SELECT deptno, job, COUNT(*), SUM(sal)
FROM emp
GROUP BY ROLLUP(deptno, job);

-- [실습 2] CUBE 함수 (결합 가능한 모든 조합의 다차원 합계 생성)
-- 결과 해석: ROLLUP과 달리 부서별 합계뿐만 아니라, 직무(JOB)별 합계까지 모든 조합을 평면적으로 다 구해줍니다.
SELECT deptno, job, COUNT(*), SUM(sal)
FROM emp
GROUP BY CUBE(deptno, job);

-- [실습 3] GROUPING SETS 함수 (지정한 항목 각각의 개별 합계만 나열)
-- 결과 해석: ROLLUP이나 CUBE처럼 복잡한 중간 합계나 전체 총합계는 싹 빼고, 오직 '부서별 합계'와 '직무별 합계'만 평면적으로 뚝 잘라서 나열해 줍니다.
SELECT deptno, job, COUNT(*), SUM(sal)
FROM emp
GROUP BY GROUPING SETS(deptno, job);

-- [실습 4] NVL과 NULL 연산의 함정 (시험 출제율 100% ??)
-- 결과 해석: 오라클에서 NULL과의 모든 사칙연산 결과는 무조건 NULL이 됩니다. 이를 방지하는 NVL 함수의 차이를 눈으로 확인합니다.
SELECT ename, sal, comm, 
       sal + comm AS 연산1, 
       sal + NVL(comm, 0) AS 연산2
FROM emp;

-- [실습 5] 윈도우 함수 순위 삼총사 (RANK / DENSE_RANK / ROW_NUMBER)
-- 결과 해석: 급여(sal)가 높은 순서대로 정렬하되, 동점자(SCOTT, FORD 등)가 나왔을 때 세 함수가 등수를 어떻게 다르게 매기는지 하단 결과창에서 비교해 보세요.
SELECT ename, sal,
       RANK() OVER (ORDER BY sal DESC) as rk,
       DENSE_RANK() OVER (ORDER BY sal DESC) as drk,
       ROW_NUMBER() OVER (ORDER BY sal DESC) as rn
FROM emp;

-- [실습 6] 순위 중복 데이터 제거 (서브쿼리와 GROUP BY 활용)
-- 결과 해석: 먼저 사원들을 급여 순으로 등수(rk)를 매긴 가상 테이블을 만들고, 등수별로 그룹을 묶어(GROUP BY) 등수당 딱 한 명의 사원만 화면에 남깁니다.
SELECT rk AS 등수, 
       MAX(ename) AS 사원명, 
       MAX(sal) AS 급여
FROM (
    SELECT ename, sal,
           RANK() OVER (ORDER BY sal DESC) AS rk
    FROM emp
)
GROUP BY rk
ORDER BY 등수;

-- [실습 7] 다중 행 서브쿼리 연산자 (ANY vs ALL) - 함정 문제 단골 출제 ?
-- 7-1. ANY 연산자: 서브쿼리가 반환한 여러 값 중 '최솟값'보다 큰 데이터를 필터링함
-- 결과 해석: 30번 부서원들의 급여(950, 1250, 1500, 1600, 2850) 중 가장 작은 값인 950보다 많이 받는 모든 사원이 출력됩니다.
SELECT ename, sal, deptno
FROM emp 
WHERE sal > ANY (SELECT sal FROM emp WHERE deptno = 30)
ORDER BY sal;

-- [실습 8] 다중 행 서브쿼리 연산자 (ALL)
SELECT ename, sal, deptno
FROM emp 
WHERE sal > ALL (SELECT sal FROM emp WHERE deptno = 30)
ORDER BY sal;

-- [실습 9] 표준 조인(JOIN USING)의 문법적 특성 (출제 기준 '표준 조인' 파트 ?)
-- 결과 해석: emp 테이블과 dept 테이블을 똑같은 이름의 컬럼인 'deptno' 기준으로 연결합니다. 
-- ?? 시험 필수 암기: USING 절에 쓰인 컬럼(deptno)은 SELECT 절에서 별칭(a.deptno 등)을 붙이면 문법 에러가 발생합니다!
SELECT ename, deptno, dname
FROM emp a JOIN dept b USING (deptno);

-- ===================================================
-- 📅 5월 28일 (목) - SQLD 실습 2일차
-- ===================================================

-- [실습 10] 전통적인 오라클 조인 vs ANSI 표준 조인 (NATURAL JOIN의 함정 ⭐)
-- 결과 해석: NATURAL JOIN은 두 테이블에서 '이름과 데이터 타입이 완전히 일치하는 모든 열'을 찾아 자동으로 조인합니다.
-- ⚠️ 시험 필수 암기: USING 절과 마찬가지로 WHERE 절이나 SELECT 절에 a.deptno 같은 식별자(접두사)를 붙이면 문법 에러가 발생합니다!
SELECT ename, deptno, dname
FROM emp NATURAL JOIN dept;

-- [실습 11] ANSI Left Outer Join vs 오라클 방식 (데이터 누락 방지 ⭐)
-- 결과 해석: 일반 조인(Inner)을 하면 사원이 한 명도 없는 40번 부서(OPERATIONS)는 결과에서 잘려 나갑니다. 
-- 하지만 OUTER JOIN을 쓰면 사원이 없더라도 부서 테이블(우측)의 데이터를 억지로 살려서 결과에 포함해 줍니다.
-- 11-1. ANSI 표준 방식 (LEFT/RIGHT OUTER JOIN)
SELECT a.ename, b.deptno, b.dname
FROM dept b LEFT OUTER JOIN emp a ON (b.deptno = a.deptno)
ORDER BY b.deptno;

-- 11-2. 전통적인 오라클 방식 (더 가치 있는 쪽의 '반대편' 컬럼 뒤에 (+)를 붙임)
-- 결과 해석: 위의 ANSI 표준 방식과 완벽하게 100% 동일한 결과를 뱉어냅니다.
SELECT a.ename, b.deptno, b.dname
FROM dept b, emp a
WHERE b.deptno = a.deptno(+)
ORDER BY b.deptno;

-- [실습 12] 계층형 질의 (조직도 및 사장-사원 상하관계 출력 ⭐⭐⭐)
-- 결과 해석: PRIOR 위치에 따라 순방향/역방향 전개가 결정됩니다. 
-- START WITH로 대장(KING)을 정하고, CONNECT BY로 사원(empno)과 직속 상사(mgr)를 연결해 계층 트리 구조를 만듭니다.
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*3) || ename AS 조직도,
       sal, job
FROM emp
START WITH mgr IS NULL          -- 직속 상사(MGR)가 없는 최고 대장(KING)부터 시작해라!
CONNECT BY PRIOR empno = mgr;   -- 사원번호(empno)가 그다음 사람의 상사번호(mgr)가 되는 순방향 전개!

-- [실습 13] 상호연관 서브쿼리 (소속 부서의 평균 급여보다 많이 받는 사원 추출 ⭐⭐⭐)
-- 결과 해석: 일반 서브쿼리와 달리, 바깥쪽 쿼리(emp m)의 부서번호(deptno)를 안쪽 서브쿼리가 받아서 
-- 해당 부서만의 평균 급여를 구한 뒤 비교합니다. 즉, 메인 쿼리의 행마다 서브쿼리가 매번 실행됩니다.
SELECT m.ename, m.deptno, m.sal
FROM emp m
WHERE m.sal > (SELECT AVG(s.sal) 
               FROM emp s 
               WHERE s.deptno = m.deptno) -- 바깥쪽 메인 쿼리의 부서번호(m.deptno)와 싱크를 맞춤!
ORDER BY m.deptno;

-- [실습 14] 인라인 뷰 기반의 Top-N 쿼리 (급여 상위 3명 추출 ⭐⭐)
-- 결과 해석: 오라클의 ROWNUM은 데이터가 추출되는 순서대로 번호가 매겨지기 때문에, 
-- 반드시 서브쿼리(인라인 뷰) 안에서 먼저 급여순 정렬(ORDER BY)을 완벽하게 끝내놓은 뒤 바깥에서 ROWNUM <= 3 조건으로 잘라야 합니다.
SELECT ROWNUM AS 순위, ename, sal
FROM (
    SELECT ename, sal
    FROM emp
    ORDER BY sal DESC -- 안쪽 가상 테이블에서 급여 높은 순으로 정렬 완료!
)
WHERE ROWNUM <= 3; -- 정렬된 상태에서 위에서부터 딱 3줄만 커트!
