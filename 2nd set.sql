-- number of students
select count(*) from students

--get students population in each year
select student_population_year_ref, count(student_epita_email) from students s group by student_population_year_ref

--get students population in each program 
select student_population_code_ref, count(student_epita_email) from students s group by student_population_code_ref

--calculate age from DOB
select contact_first_name, contact_last_name ,contact_birthdate, date_part('year', age(contact_birthdate)) from contacts c

--add age column to contacts
ALTER TABLE contacts
add contact_age integer null

--add age to age list from dob
update contacts 
set contact_age = date_part('year', age(contact_birthdate))
--or 
update contacts as c1 set contact_age = 
(SELECT date_part('year',age(contact_birthdate)) as c_age 
 FROM contacts as c2 where c1.contact_email=c2.contact_email);

--avg students age
select avg(contact_age) as avg_student_age
from contacts c inner join students s
on c.contact_email = s.student_contact_ref

--avg session duration for a course
select avg(EXTRACT(EPOCH FROM TO_TIMESTAMP(session_end_time, 'HH24:MI:SS')::TIME - TO_TIMESTAMP(session_start_time, 'HH24:MI:SS')::TIME)/3600) as duration 
from sessions as s left join courses as c
on c.course_code=s.session_course_ref
where c.course_code='SE_ADV_DB'

--student with most absences
select count(a.attendance_student_ref) as absences,
c.contact_first_name, c.contact_last_name
from contacts as c
left join students as s on s.student_contact_ref=c.contact_email
left join attendance as a on s.student_epita_email=a.attendance_student_ref
where a.attendance_presence=0
group by c.contact_first_name, c.contact_last_name
order by absences desc 
limit 1

--find course with most absences
select c.course_name, count(a.attendance_presence) 
	from attendance a inner join courses c 
		on attendance_course_ref = c.course_code 
			where attendance_presence = 0
				group by c.course_name
					order by count desc 
						limit 1

-- find students who are not graded
select s.student_epita_email, g.grade_score 
from students s right join grades g
on s.student_epita_email = g.grade_student_epita_email_ref
where g.grade_score is null

--teachers that are not present in any session 
select t.teacher_epita_email from teachers t 
left outer join sessions s 
on teacher_epita_email = s.session_prof_ref 
where s.session_prof_ref is null

--list of teachers who attended the total sessions
select con.contact_first_name, con.contact_last_name, tea.teacher_contact_ref, count(session_prof_ref)
	from teachers tea
	inner join contacts con
	on con.contact_email = tea.teacher_contact_ref
	inner join sessions sess
	on tea.teacher_epita_email = sess.session_prof_ref
group by con.contact_first_name, con.contact_last_name, tea.teacher_contact_ref
order by count

--find the DSA students details with grades
select  c.contact_first_name , c.contact_last_name , s.student_population_code_ref , g.grade_course_code_ref as course_name, g.grade_score
from students s inner join grades g
on s.student_epita_email = g.grade_student_epita_email_ref
inner join contacts c on s.student_contact_ref = c.contact_email 
where s.student_population_code_ref = 'DSA'

--attendance percentage for a given student for all courses enrolled in
select (sum_attendance/total_attendance::float)*100 as attendance_percentage, attendance_student_ref, attendance_course_ref from
(
	select count(*) as total_attendance, sum(attendance_presence) as sum_attendance, attendance_student_ref,attendance_course_ref from attendance
	where attendance_student_ref ='jamal.vanausdal@epita.fr'
	group by attendance_student_ref, attendance_course_ref
) as res
order by attendance_percentage

--avg grade for DSA students
select s.student_population_code_ref, avg(g.grade_score) as avg_grade from grades g
left join students s on g.grade_student_epita_email_ref = s.student_epita_email
where s.student_population_code_ref = 'DSA'
group by s.student_population_code_ref

--all students avg grade
select c.contact_first_name, c.contact_last_name, s.student_epita_email , avg(grade_score) 
from grades g inner join students as s
on g.grade_student_epita_email_ref = s.student_epita_email 
inner join contacts as c
on s.student_contact_ref = c.contact_email
group by c.contact_first_name,c.contact_last_name, s.student_epita_email
order by avg desc

--list courses taught by teachers
select c.course_code, c2.contact_first_name, c2.contact_last_name 
from sessions s inner join courses c 
on s.session_course_ref = c.course_code 
inner join teachers t 
on s.session_prof_ref = t.teacher_epita_email 
inner join contacts c2 on t.teacher_contact_ref = c2.contact_email 

select distinct con.contact_first_name, con.contact_last_name, sess.session_course_ref
	from teachers tea
	inner join contacts con
	on con.contact_email = tea.teacher_contact_ref
	inner join sessions sess
	on tea.teacher_epita_email = sess.session_prof_ref

--teachers not giving any course
select * from teachers t 
left join sessions s 
on s.session_prof_ref = t.teacher_epita_email 
left join courses c on s.session_course_ref = c.course_code 
where s.session_course_ref is null;


--1 list of students in a given year period and program
select * from students
where student_population_period_ref = 'SPRING' 
and student_population_year_ref = '2021' 
and student_population_code_ref = 'SE'

--2 get nb of enrolled of enrolled students in a given year period and program 
select count(1) from students
where student_population_period_ref = 'SPRING' 
and student_population_year_ref = '2021' 
and student_population_code_ref = 'SE'

--3 get all defined exams for a course from grades table
select g.grade_course_code_ref, g.grade_exam_type_ref from grades g
where g.grade_course_code_ref ='SE_ADV_JAVA'
group by g.grade_course_code_ref, g.grade_exam_type_ref

--4 get all grades for a given student
select c.contact_first_name,c.contact_last_name, g.grade_course_code_ref, g.grade_score from grades g
inner join students s on g.grade_student_epita_email_ref = s.student_epita_email 
inner join contacts c on s.student_contact_ref = c.contact_email 
where g.grade_student_epita_email_ref='jamal.vanausdal@epita.fr'

--5 get all grades for a specific exam
select g.grade_course_code_ref,g.grade_exam_type_ref,g.grade_score from grades g 
where g.grade_course_code_ref = 'SE_ADV_JS'

--6 get students ranks in an exam for a course
select c.contact_first_name, c.contact_last_name, g.grade_course_code_ref, g.grade_exam_type_ref, g.grade_score,
rank() over(order by g.grade_score desc) as rnk
from grades g inner join students s 
on g.grade_student_epita_email_ref = s.student_epita_email
inner join contacts c
on s.student_contact_ref = c.contact_email
where g.grade_course_code_ref = 'SE_ADV_JS'


--7 get students ranks in all exams for a course
select c.contact_first_name, c.contact_last_name, g.grade_course_code_ref, g.grade_exam_type_ref, g.grade_score,
rank() over(partition by g.grade_exam_type_ref order by g.grade_score desc) as rnk
from grades g inner join students s 
on g.grade_student_epita_email_ref = s.student_epita_email
inner join contacts c
on s.student_contact_ref = c.contact_email
where g.grade_course_code_ref = 'SE_ADV_JAVA'

--8 get students ranks in all exams and all courses
select c.contact_first_name, c.contact_last_name, g.grade_course_code_ref, g.grade_exam_type_ref, g.grade_score,
rank() over(partition by g.grade_exam_type_ref,g.grade_course_code_ref order by g.grade_score desc) as rnk
from grades g inner join students s 
on g.grade_student_epita_email_ref = s.student_epita_email
inner join contacts c
on s.student_contact_ref = c.contact_email

--9 Get all courses for one program
select p.program_assignment, c.course_name, p.program_course_code_ref 
from programs p inner join courses c on p.program_course_code_ref = c.course_code 
where p.program_assignment = 'SE'

--10 Get courses in common between 2 programs
select c.course_name
from courses c inner join programs p 
on c.course_code = p.program_course_code_ref
where p.program_assignment ='DSA'
intersect 
select c.course_name 
from courses c inner join programs p 
on c.course_code = p.program_course_code_ref
where p.program_assignment ='CS'

--11 Get all programs following a certain course
select p.program_assignment 
from courses c inner join programs p 
on c.course_code = p.program_course_code_ref
where c.course_code = 'AI_DATA_SCIENCE_IN_PROD'

--12 get course with the biggest duration
with course_duration_rank as (
    select duration, c.course_name,
    rank() over(order by duration desc) as rnk 
    from courses c
)
select duration ,course_name, rnk
from course_duration_rank
where rnk = 1;

--13 Get courses with the same duration
select course_name, duration from courses where duration in (
select duration from courses
group by duration having count(*) > 1
)
order by duration desc

--14 Get all sessions for a specific course
select s.session_course_ref,s.session_type, s.session_date from sessions s 
where s.session_course_ref = 'AI_DATA_PREP'

--15 Get all sessions for a certain period
select s.session_course_ref,s.session_type, s.session_date from sessions s 
where s.session_date between '2020-11-01' and '2020-11-30'

--16 Get one student attendance sheet
select c.contact_first_name, s.student_epita_email , a.attendance_session_date_ref, a.attendance_course_ref, a.attendance_presence from attendance a
left join students s on s.student_epita_email = a.attendance_student_ref
left join contacts c on c.contact_email = s.student_contact_ref
where s.student_epita_email = 'jamal.vanausdal@epita.fr'

--17 Get one student summary of attendance / SAME

--18 Get student with most absences
select count(a.attendance_student_ref) as absences,
c.contact_first_name, c.contact_last_name 
from contacts as c 
left join students as s on s.student_contact_ref=c.contact_email 
left join attendance as a on s.student_epita_email=a.attendance_student_ref 
where a.attendance_presence=0 
group by c.contact_first_name, c.contact_last_name 
order by absences desc  
limit 1

--1 hard questions - get all exams for a specific course
select e.exam_course_code, e.exam_weight, e.exam_type from exams e
where e.exam_course_code ='SE_ADV_JAVA'

--2 get all grades for a specific student
select c.contact_first_name,c.contact_last_name, g.grade_course_code_ref, g.grade_score from grades g
inner join students s on g.grade_student_epita_email_ref = s.student_epita_email 
inner join contacts c on s.student_contact_ref = c.contact_email 
where g.grade_student_epita_email_ref='jamal.vanausdal@epita.fr'

--3 Get the final grades for a student on a specifique course or all courses
select s.student_epita_email ,g.grade_course_code_ref, sum(e.exam_weight * g.grade_score)/sum(e.exam_weight) from grades g 
inner join exams e on g.grade_course_code_ref = e.exam_course_code
inner join students s on g.grade_student_epita_email_ref =s.student_epita_email 
where s.student_epita_email ='jamal.vanausdal@epita.fr' 
group by g.grade_course_code_ref, s.student_epita_email  

--4 Get the students with the top 5 scores for specific course
with total_grade_course as (
	select c.contact_first_name, c.contact_last_name ,g.grade_course_code_ref, sum(e.exam_weight * g.grade_score)/sum(e.exam_weight) as total_grade,
	rank() over (partition by g.grade_course_code_ref order by sum(e.exam_weight * g.grade_score)/sum(e.exam_weight) desc) as rnk
	from grades g 
	inner join exams e on g.grade_course_code_ref = e.exam_course_code
	inner join students s on g.grade_student_epita_email_ref = s.student_epita_email
	inner join contacts c on s.student_contact_ref = c.contact_email 
	group by g.grade_course_code_ref, c.contact_first_name, c.contact_last_name
)
select contact_first_name, contact_last_name, grade_course_code_ref, total_grade, rnk
from total_grade_course
where rnk <=5 and grade_course_code_ref ='DT_RDBMS'

--5 Get the students with the top 5 scores for specific course

--6 Get the class average for a course
select g.grade_course_code_ref, (sum(e.exam_weight * g.grade_score)/sum(e.exam_weight)::float) as class_average
from grades g inner join exams e on g.grade_course_code_ref = e.exam_course_code
inner join students s on g.grade_student_epita_email_ref =s.student_epita_email 
group by g.grade_course_code_ref
