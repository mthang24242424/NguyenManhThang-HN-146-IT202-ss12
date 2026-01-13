USE StudentDB;
-- câu 1
create view View_StudentBasic as
select s.studentid, s.fullname, d.deptname
from student s
join department d on s.deptid = d.deptid;

select * from View_StudentBasic;
-- câu 2
create index idx_student_fullname
on student(fullname);

-- câu 3
delimiter $$
create procedure GetStudentsIT()
begin
    select s.studentid, s.fullname, d.deptname
    from student s
    join department d on s.deptid = d.deptid
    where d.deptname = 'information technology';
end $$
delimiter ;

call GetStudentsIT();

-- câu 4
create view View_StudentCountByDept  as
select d.deptname, count(s.studentid) as totalstudents
from department d
left join student s on d.deptid = s.deptid
group by d.deptname;

select * from View_StudentCountByDept 
where totalstudents = (
    select max(totalstudents)
    from View_StudentCountByDept 
);

-- câu 5
delimiter $$
create procedure GetTopScoreStudent(in p_courseid char(6))
begin
    select s.studentid, s.fullname, e.score, c.coursename from enrollment e
    join student s on e.studentid = s.studentid
    join course c on e.courseid = c.courseid
    where e.courseid = p_courseid
      and e.score = (
          select max(score) from enrollment
          where courseid = p_courseid
      );
end $$
delimiter ;

call GetTopScoreStudent('C00001');

-- câu 6
create view View_IT_Enrollment_DB as
select e.studentid, e.courseid, e.score from enrollment e
join student s on e.studentid = s.studentid
where s.deptid = 'it' and e.courseid = 'c00001' with check option;

delimiter $$
create procedure updatescore_it_db(
    in p_studentid char(6),
    inout p_newscore float
)
begin
    if p_newscore > 10 then
        set p_newscore = 10;
    end if;

    update View_IT_Enrollment_DB
    set score = p_newscore
    where studentid = p_studentid;
end $$
delimiter ;

set @newscore = 12;
call View_IT_Enrollment_DB('s00001', @newscore);

select @newscore as diemsaucapnhat;
select * from View_IT_Enrollment_DB;
