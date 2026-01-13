use social_network_mini;

select * from users;

create or replace view vw_public_users as
select user_id, username, created_at
from users;

select * from vw_public_users;
select user_id, username, created_at from users;

create index idx_users_username on users(username);
select * from users where username = 'an.nguyen';

delimiter $$

create procedure sp_create_post(
  in p_user_id int,
  in p_content text
)
begin
  if exists (select 1 from users where user_id = p_user_id) then
    insert into posts(user_id, content)
    values (p_user_id, p_content);
  else
    signal sqlstate '45000'
    set message_text = 'user khong ton tai';
  end if;
end $$

delimiter ;

call sp_create_post(1,'bai viet dau tien');

create or replace view vw_recent_posts as
select p.post_id, p.content, p.created_at, u.username
from posts p
join users u on p.user_id = u.user_id
where p.created_at >= now() - interval 7 day;

select * from vw_recent_posts order by created_at desc;

select * 
from posts 
where user_id = 1
order by created_at desc;

delimiter $$

create procedure sp_count_posts(
  in p_user_id int,
  out p_total int
)
begin
  select count(*) into p_total
  from posts
  where user_id = p_user_id;
end $$

delimiter ;

call sp_count_posts(1,@total);
select @total as tong_bai_viet;

delimiter $$

create procedure sp_add_friend(
  in p_user_id int,
  in p_friend_id int
)
begin
  if p_user_id = p_friend_id then
    signal sqlstate '45000'
    set message_text = 'khong the ket ban voi chinh minh';
  else
    insert into friends(user_id, friend_id, status)
    values (p_user_id, p_friend_id, 'pending');
  end if;
end $$

delimiter ;

delimiter $$

create procedure sp_suggest_friends(
  in p_user_id int,
  inout p_limit int
)
begin
  declare cnt int default 0;

  while cnt < p_limit do
    select user_id, username
    from users
    where user_id <> p_user_id
    limit p_limit;

    set cnt = cnt + 1;
  end while;
end $$

delimiter ;
set @lim = 3;
call sp_suggest_friends(1,@lim);

create or replace view vw_top_posts as
select p.post_id, p.content, count(l.user_id) as total_likes
from posts p
left join likes l on p.post_id = l.post_id
group by p.post_id
order by total_likes desc
limit 5;

select * from vw_top_posts;

delimiter $$

create procedure sp_add_comment(
  in p_user_id int,
  in p_post_id int,
  in p_content text
)
begin
  declare user_cnt int;
  declare post_cnt int;

  select count(*) into user_cnt from users where user_id = p_user_id;
  select count(*) into post_cnt from posts where post_id = p_post_id;

  if user_cnt = 0 then
    signal sqlstate '45000' set message_text = 'user khong ton tai';
  elseif post_cnt = 0 then
    signal sqlstate '45000' set message_text = 'post khong ton tai';
  else
    insert into comments(user_id, post_id, content)
    values (p_user_id, p_post_id, p_content);
  end if;
end $$

delimiter ;

create or replace view vw_post_comments as
select c.content, u.username, c.created_at
from comments c
join users u on c.user_id = u.user_id;

delimiter $$

create procedure sp_like_post(
  in p_user_id int,
  in p_post_id int
)
begin
  if exists (
    select 1 from likes 
    where user_id = p_user_id and post_id = p_post_id
  ) then
    signal sqlstate '45000'
    set message_text = 'da like roi';
  else
    insert into likes(user_id, post_id)
    values (p_user_id, p_post_id);
  end if;
end $$

delimiter ;

create or replace view vw_post_likes as
select post_id, count(*) as total_likes
from likes
group by post_id;

delimiter $$

create procedure sp_search_social(
  in p_option int,
  in p_keyword varchar(100)
)
begin
  if p_option = 1 then
    select * from users
    where username like concat('%',p_keyword,'%');

  elseif p_option = 2 then
    select * from posts
    where content like concat('%',p_keyword,'%');

  else
    signal sqlstate '45000'
    set message_text = 'option khong hop le';
  end if;
end $$

delimiter ;

call sp_search_social(1,'an');
call sp_search_social(2,'database');
