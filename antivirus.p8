pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--variables

function _init()
  --level
  set_level(0)
  
  --physics
  gravity=0.3
  friction=0.85
  
  --timer
  timer_on=false
  timer=0
  timer_func=nil
  
  --menu
  menuitem(1,"retry level",
  function() retry_level() end)
end

function set_level(new_level)
  level=new_level
  init_player()
  
  --player position
  player.x=level*256
  player.y=27*8
  
  --camera
  camera_x=level*256
  camera_y=128
  
  --map limit
  map_start_x=level*256
  map_end_x=(level+1)*256
  map_start_y=0
  map_end_y=256
end

function init_player()
  player={
    --position
    sp=1,
    x=0,
    y=0,
    w=7,
    h=8,
    flp=false,
    --movement
    dx=0,
    dy=0,
    max_dx=1.8,
    max_dy=3,
    acc=0.35,
    jump=3.5,
    --states
    anim=0,
    running=false,
    jumping=false,
    falling=false,
    sliding=false,
    landed=false,
    sleeping=false,
    --items
    files=0,
    viruses=0,
    keys1=0,
    keys2=0
  }
  
  --debug
  --x1r=0	y1r=0
  --x2r=0	y2r=0
  
  --collide_l="no"
  --collide_r="no"
  --collide_u="no"
  --collide_d="no"
end

function next_level()
	 level+=1
	 set_level(level)
end

function retry_level()
  cls()
  reset()
  reload()
  init_player()
end
-->8
--update/draw

function _update()
  --player
  player_update()
  player_animate()
  player_interact()
  
  --camera
  cam_x=player.x-64+(player.w/2)
  cam_x=mid(map_start_x,cam_x,map_end_x-128)
  
  cam_y=player.y-64+(player.h/2)
  cam_y=mid(map_start_y,cam_y,map_end_y-128)
  
  --timer
  if timer_on then
    if time()-timer>3 then
      timer_on=false
      timer_func()
    end
  end
  
  --debug reset
  --if btnp(⬇️) then
  --  retry_level()
  --end
  
  camera(cam_x,cam_y)
end

function _draw()
  --fade to black
  if timer_on then
    if time()-timer>2 then
      cls(0)
      return
    elseif time()-timer>1 then
      cls(1)
      spr(player.sp,player.x,player.y,1,1,player.flp)
      return
    end
  end
  
  --draw normally
  cls(1)
  map(0,0)
  
  spr(player.sp,player.x,player.y,1,1,player.flp)
  --debug_draw()
end

function debug_draw()
		rect(x1r,y1r,x2r,y2r,7)
		print("⬅️="..collide_l,player.x,player.y-10,7)
		print("➡️="..collide_r,player.x,player.y-16,7)
		print("⬆️="..collide_u,player.x,player.y-22,7)
		print("⬇️="..collide_d,player.x,player.y-28,7)
end
-->8
--collision

function collide_map(obj,aim,flag)
  local x=obj.x  local y=obj.y
  local w=obj.w  local h=obj.h
  
  local x1=0 local y1=0
  local x2=0 local y2=0
  
  --find hitbox position
  --aligh hitbox with sprite
  if aim=="left" then
    x1=x+0    y1=y+1
    x2=x+2    y2=y+h-1
  elseif aim=="right" then
    x1=x+w-2  y1=y+1
    x2=x+w-0  y2=y+h-1
  elseif aim=="up" then
    x1=x+1    y1=y
    x2=x+w-2  y2=y
    if player.flp then
      x1+=1
      x2+=1
    end
  elseif aim=="down" then
    x1=x+1    y1=y+h
    x2=x+w-2  y2=y+h+1
    if player.flp then
      x1+=1
      x2+=1
    end
  end
  
  --debug
  x1r=x1 y1r=y1
  x2r=x2	y2r=y2
  
  --convert pix to tiles
  x1/=8  y1/=8
  x2/=8  y2/=8
  
  if fget(mget(x1,y1),flag)
  or fget(mget(x1,y2),flag)
  or fget(mget(x2,y1),flag)
  or fget(mget(x2,y2),flag) then
    return true
  else
    return false
  end
end
-->8
--player update

function player_update()
  --physics
  player.dy+=gravity
  player.dx*=friction
  
  if not player.sleeping then
    player_input()
    player_collide()
    player_move()
  end
end

function player_input() 
  --run
  if btn(⬅️) then
    player.dx-=player.acc
    player.running=true
    player.flp=true
  end
  if btn(➡️) then
    player.dx+=player.acc
    player.running=true
    player.flp=false
  end
  
  --slide
  if player.running
  and not btn(⬅️)
  and not btn(➡️)
  and player.landed then
    player.running=false
    player.sliding=true
  end
  
  --jump
  if btnp(❎)
  and player.landed then
    player.dy-=player.jump
    player.landed=false
    sfx(0)
  end
end

function player_collide()
  --vertical collision
  if player.dy>0 then
    player.falling=true
    player.landed=false
    player.jumping=false
    
    if collide_map(player,"down",0) then
      player.landed=true
      player.falling=false
      player.dy=0
      --correct position
      player.y-=((player.y+player.h+1)%8)-1
    --debug
      collide_d="yes"
    else
    		collide_d="no"
    end
  elseif player.dy<0 then
    player.jumping=true
    
    if collide_map(player,"up",1) then
      player.dy=0
    --debug
      collide_u="yes"
    else
    		collide_u="no"
    end
  end
  
  --horizontal collision
  if player.dx<0 then
    if collide_map(player,"left",1) then
      player.dx=0
    --debug
      collide_l="yes"
    else
    		collide_l="no"
    end
  elseif player.dx>0 then
    if collide_map(player,"right",1) then
      player.dx=0
    --debug
      collide_r="yes"
    else
    		collide_r="no"
    end
  end
end

function player_move()
  --stop slide
  if player.sliding then
    if abs(player.dx)<0.5
    or player.running then
      player.dx=0
      player.sliding=false
    end
  end

  --limit speed
  player.dx=clamp(player.dx,player.max_dx)
  player.dy=clamp(player.dy,player.max_dy)
  
  --move
  player.x+=player.dx
  player.y+=player.dy
  
  --limit to map
  player.x=mid(map_start_x,player.x,map_end_x-player.w)
  player.y=mid(map_start_y,player.y,map_end_y-player.h)
end

function clamp(num,maximum)
  return mid(-maximum,num,maximum)
end
-->8
--player anim

function player_animate()
  if player.sleeping then
  		player.sp=12
  elseif player.jumping then
    player.sp=5
  elseif player.falling then
    player.sp=6
  elseif player.sliding then
    player.sp=7
  elseif player.running then
    if time()-player.anim>0.12 then
      player.anim=time()
      player.sp+=1
      if player.sp>4 then
        player.sp=3
      end
    end
  else --idle
    if time()-player.anim>0.6 then
      player.anim=time()
      player.sp+=1
      if player.sp>2 then
        player.sp=1
      end
    end
  end
end
-->8
--player interact

function player_interact()
  local tile_x=(player.x+player.w/2)/8
  local tile_y=(player.y+player.h/2)/8
  local tile_spr=mget(tile_x,tile_y)
  local tile_spr_l=mget(tile_x-1,tile_y)
  local tile_spr_r=mget(tile_x+1,tile_y)
  
  --pickup item
  if fget(tile_spr,2) then
    pickup_item(tile_x,tile_y,tile_spr)
  end
  
  --use item/tile
  if btnp(🅾️) then
  		--use object at position
    if fget(tile_spr,3) then
      use_object(tile_x,tile_y,tile_spr)
    --use object to left
    elseif fget(tile_spr_l,3)
    and btn(⬅️) then
      use_object(tile_x-1,tile_y,tile_spr_l)
    --use object to right
    elseif fget(tile_spr_r,3)
    and btn(➡️) then
      use_object(tile_x+1,tile_y,tile_spr_r)
    end
  end
end

function pickup_item(tile_x,tile_y,tile_spr)
 	--file
  if tile_spr==16 then
    mset(tile_x,tile_y,0)
    player.files+=1
    sfx(1)
  --virus
  elseif tile_spr==24 then
    mset(tile_x,tile_y,0)
    player.viruses+=1
    sfx(1)
  --silver key
  elseif tile_spr==22 then
    mset(tile_x,tile_y,0)
    player.keys1+=1
    sfx(3)
   --gold key
  elseif tile_spr==23 then
    mset(tile_x,tile_y,0)
    player.keys2+=1
    sfx(3)
  end
end

-->8
--use objects

function use_object(tile_x,tile_y,tile_spr)
  --folder has room
  if tile_spr==17
  or tile_spr==18 then
    --check for file
    if player.files>0 then 
      mset(tile_x,tile_y,tile_spr+1)
      player.files-=1
      sfx(1)
    else
      sfx(2)
    end
  --folder drops silver key
  elseif tile_spr==19 then
    mset(tile_x,tile_y,tile_spr+1)
 			player.keys1+=1
 			sfx(3)
  --folder is full
  elseif tile_spr==20 then
    sfx(2)
  --folder/wall is locked
  elseif tile_spr==21 then
    --check for silver key
  		if player.keys1>0 then 
      mset(tile_x,tile_y,17)
      player.keys1-=1
      sfx(3)
    else
      sfx(2)
    end
  
  --trash has room
  elseif tile_spr>=25
  and tile_spr<=27 then
    --check for virus
    if player.viruses>0 then 
      mset(tile_x,tile_y,tile_spr+1)
      player.viruses-=1
      sfx(1)
    else
      sfx(2)
    end
  --trash drops gold key
  elseif tile_spr==28 then
    mset(tile_x,tile_y,tile_spr+1)
 			player.keys2+=1
 			sfx(3)
  --trash is full
  elseif tile_spr==29 then
    sfx(2)
  
  --silver lock block
  elseif tile_spr==32 then
    --check for silver key
  		if player.keys1>0 then 
      mset(tile_x,tile_y,0)
      player.keys1-=1
      sfx(3)
    else
      sfx(2)
    end
  --gold lock block
  elseif tile_spr==33 then
    --check for gold key
  		if player.keys2>0 then 
      mset(tile_x,tile_y,0)
      player.keys2-=1
      sfx(3)
    else
      sfx(2)
    end
  
  --power button
  elseif tile_spr==37
  --player on ground
  and player.landed then
    mset(tile_x,tile_y,tile_spr+1)
    sfx(4)
    --go to sleep
    player.sleeping=true
    player.running=false
    --restart game
    timer_on=true
    timer=time()
    timer_func=function()
      next_level()
    end
  --restart button
  elseif tile_spr==39
  --player on ground
  and player.landed then
    sfx(4)
    --go to sleep
    player.sleeping=true
    player.running=false
    --restart game
    timer_on=true
    timer=time()
    timer_func=function()
      set_level(0)
    end
  end
end
__gfx__
00000000005555000055550000555500005555000055550000555500005555000055550000555500005555000055550000555500000000000000000000000000
0000000005b6bb0005b6bb0005b6bb0005b6bb0005b6bb0005b6bb0005b6bb0005c6cc0005c6cc00059699000586880005161100000000000000000000000000
0070070005bb6b0005bb6b0005bb6b0005bb6b0005bb6b0005bb6b0005bb6b0005cc6c0005cc6c00059969000588680005116100000000000000000000000000
00077000005555000055550000555500005555000055550050555550005555005055555000555500005555000055550000555500000000000000000000000000
000770000ddddd000ddddd000dddd0000dddd0000ddddd000ddddd000ddddd000ddddd005ddddd505ddddd505ddddd500ddddd00000000000000000000000000
0070070005ddd50050ddd05050dddd5005ddd50050ddd05000ddd00050ddd05000ddd00000ddd00000ddd00000ddd00005ddd500000000000000000000000000
0000000000d0d00000d0d00000d0d00000dd000000d0d00000d0d00000d0d00000d0d00000d0d00000d0d00000d0d00000d0d000000000000000000000000000
00000000005050000050500005005000005500000505000000050500000505000050500000505000050005000500050000505000000000000000000000000000
07777000fff00000fff00000fff00000fff00000fff00000000000000000000000888882000550000005500000055000000aa000000550000000000000000000
07777700ffff9999f7779999f7777799f7777799ff666699000000000000000008888880555555555555555555555555088a8a80055555500000000000000000
076666709999999997777999966777799777777999699699066000000aa0000008555580660000666600006666000066668aa866668888660000000000000000
07777770ffffffffffffffff67766666ffffffffff6ff6ff60066666a00aaaaa08888880060000600600006006888860068a8860068888600000000000000000
07666670ffffffffffffffff67767769fffffffff666666f60060060a00a0a0a08555580060000600600006006888860068aa860068888600000000000000000
07777770ffffffffffffffff96677769fffffffff665566f066000600aa000a00888888006000060068888600688886006a88a60068888600000000000000000
07666670ffffffffffffffff97777779fffffffff665666f000000000000000008555880060000600688886006888860068aa860068888600000000000000000
07777770fffffffffffffffffffffffffffffffff666666f00000000000000008888880000666600006666000066660000666600006666000000000000000000
0066660000aaaa00000000004444442200006660000bb00000088000000090000000000000000000000000000000000000000000000000000000000000000000
0060060000a00a00000000004222944400065dd6000bb00000088000000990000000000000000000000000000000000000000000000000000000000000000000
0060060000a00a0000000000444992240006ddd60b0bb0b008088080009999900000000000000000000000000000000000000000000000000000000000000000
066666600aaaaaa000000000229999440006dd56b00bb00b80088008000990090000000000000000000000000000000000000000000000000000000000000000
066556600aa99aa0000000004999a99200056660b00bb00b80088008900090090000000000000000000000000000000000000000000000000000000000000000
066566600aa9aaa000000000429aa94400500000b000000b80000008900000090000000000000000000000000000000000000000000000000000000000000000
066566600aa9aaa00000000044499422050000000b0000b008000080090000900000000000000000000000000000000000000000000000000000000000000000
066666600aaaaaa000000000442224445000000000bbbb0000888800009999000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333363633333333333336363330000000000000000000000000000000000000000
333333333333333333a3a33333333333355533333333555333a3a33333a3a3333363633333a3a333336363330000000000000000000000000000000000000000
3333333333333333336363333555553335a5333333335a5333636333336363333363633333636333336363330000000000000000000000000000000000000000
333333336666666666666666615a516635a1666666661a5333666666666666a36615166666666666666366660000000000000000000000000000000000000000
333333333333333333333333355a553335a5333333335a5333633333333363333355533333333333333333330000000000000000000000000000000000000000
333333336666666666666666615a516635a1666666661a5333636666666366a36615166666636666666366660000000000000000000000000000000000000000
33333333333333333333333335555533355533333333555333636333336363333333333333636333336363330000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333636333336363333333333333636333336363330000000000000000000000000000000000000000
33333333336363333363633333636333333333333363633333636333336363333363633333636333336363330000000000000000000000000000000000000000
33131333336363333363633333636333355555533363633333636333336363333363633333636333336363330000000000000000000000000000000000000000
3355533333636333336363333515153335aaaa533363633333636333336363333363633333636333336363330000000000000000000000000000000000000000
355a551333636333336366a335555533351515533363633333151666666366a333151666666366a3661516660000000000000000000000000000000000000000
35aaa533336363333363633335aaa533336363333515155333555333333363333355533333636333335553330000000000000000000000000000000000000000
355a551333636333336366a3355555333363633335aaaa5333551666666666a333151666666366a3661516660000000000000000000000000000000000000000
33555333336363333363633335151533336363333555555333333333333333333363633333636333336363330000000000000000000000000000000000000000
33333333336363333363633333636333336363333333333333333333333333333363633333636333336363330000000000000000000000000000000000000000
cccccccc00cccc00ccc6000000006ccc0000ccc66ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6ccc6cc00cccc00cc6c00000000c6cc0000cc6cc6cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc66cc6c00cc6c00c6cc00000000cc6c0000cc6cc6cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc00cccc00c6cc00000000cc6c0000c6cccc6c000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc00c6cc00000000cc6c0000c6cccc6c000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc6c00c6cc00000000cc6c0000cc6cc6cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c6cc00cc6c00000000c6cc0000cc6cc6cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc00ccc6000000006ccc0000ccc66ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000004080808080b040404080808080800000b0b00000008080800000000000000000000000000000000000000000000000003030303030303030303030000000000030303030303030303030300000000000101010101010000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4044494341474050464143494241434540504442414243455040444242434147404449434147405046414349424143454050444241424345504044424243414740444943414740504641434942414345405044424142434550404442424341470000000000000000000000000000000000000000000000000000000000000000
0000520010530000530000511000000000000021202000000000000000151751000052001853000053000051100000000000002120210000000000000015175100005200185310005300115110000000000000212021000000000000001519510000000000000000000000000000000000000000000000000000000000000000
0000550060516000510060536000005460606046414245000000000044414257000055006051600051006053600000546060604641424500000000004441425700005500605160005100605360000054606060464142450000000000444142570000000000000000000000000000000000000000000000000000000000000000
2500210000550000521000520000005110000053000000000000000000000040250021000055000052180052000000511000005319000000000000000000184025002100005500005218005200001151180000531900000000000000000018400000000000000000000000000000000000000000000000000000000000000000
5044476000400060556000550000605260000056424500006060600000444347504447600040006055600055000060526000005642450000006200000044434750444760004000605560005300006052600000564245000000620000004443470000000000000000000000000000000000000000000000000000000000000000
1000520011501000000000211000005300000050160000000000000000000051100052001950180000000021100000530000005016000000000000000000005110005200195018000000005110000053000019501800000000000000000010510000000000000000000000000000000000000000000000000000000000000000
6000550060546000000060546000005500006046450000646060606500004459600055006054600000006054600000550000604645000062000000630000445960005500605460000000605160000055000060464500006200180063000044590000000000000000000000000000000000000000000000000000000000000000
0000000000520000000000520000002000000051000000000000000000001053000000000052000000000052000000200000005118000000000000000000105300000000005200000010005200000020000000511000000000000000000018530000000000000000000000000000000000000000000000000000000000000000
6060546000516060546000550000605060000058424500000000000000444259606054600051606054600055000060506000005842450000006300000044425960605460005160605460005560606050600000584245000000630000004442590000000000000000000000000000000000000000000000000000000000000000
1700520000531700550011501100005400001052100000000000000000000051180052001053160055001850110000540000105210000000000000000000185118005200105310005500180000000054000018521800000000000000000016510000000000000000000000000000000000000000000000000000000000000000
6000550060516000500060406060605200006056434145006060600046424357600055006051600050006040606060520000605643414500000000004642435760005500605160005000605460000052000060564341450000000000464243570000000000000000000000000000000000000000000000000000000000000000
0000200000550000200000540000005111000050000015000000000053100040000020000055000021000054000000511100005000002000000000005310004000002000005500002100005300000051180000500000200000000018531000400000000000000000000000000000000000000000000000000000000000000000
0060546000500060546000510000605360000054006044424945504457600050006054600050006054600051000060536000005400604442494550445760005000605460005000605460605500006053600000540060444249455044576000500000000000000000000000000000000000000000000000000000000000000000
0000530000210000520000531700005500000052160000005500000000001054180053000015000052001953170000550000005200000000550000000000105418005300112010005200191500000055000000521100000055000000000010540000000000000000000000000000000000000000000000000000000000000000
6000520060546000510060526000002000006051600000002100000000006053600052006054600051006052600000200000605160000000150000000000605360005200605460005100605460000021000060516000000021000000000060530000000000000000000000000000000000000000000000000000000000000000
4441484342574050564342484142434149434248434149434245000000444159444148434257405056434248414243414943424843414943424500000044415944414843425740505643424841424341494342484341494342450000004441590000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000051000000000055005000006300000051000000000000000000000000000000005100000000005500500000600000005100000000000000000000000000000000510000000000550050000018000000510000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001000000052000011000020004000000000001753000000000000000000000000001800005200000000102000400000160000005300000000000000000000000000190000521100000010200040000060000018530000000000000000000000000000000000000000000000000000000000000000
0000646000000000000000006065000051006460606054005400006460606052006460000000000000000000006065005100000064605400546060606500445900000000000000000000000000606500516000000060540054000000000044590000000000000000000000000000000000000000000000000000000000000000
0000000000006060606000000000000053000000000052005300000000000053000000000000606060600000000000005300000000005200530000000000005300001800000060606060000000000000530000000000520053000000000000530000000000000000000000000000000000000000000000000000000000000000
0000001000000000000000001100000052006200000053005200620000000051000018000000000000000000001900005200006200005300520000620000005100646000000000000000000000180000520062000000530052000000620000510000000000000000000000000000000000000000000000000000000000000000
0000646000000000000000006065000051000000000051005100000000000052006460000000000000000000006065005100000000005100510000000000005200000000000000000000000000606500510000000000510051190000000000520000000000000000000000000000000000000000000000000000000000000000
0000000000006060606000000000000055000000630052005560606065000055000000000000606060600000000000005500000063005200564500000000005500000000000060606060000000000044570000006300520058450000000000550000000000000000000000000000000000000000000000000000000000000000
0000001000000000000000000000000040000000000055005400000000000050000018000000000000000000001000004011000000005500540000006300005000001800000000000000000000000000210000100000550052000000006300500000000000000000000000000000000000000000000000000000000000000000
0000646000000000000000006065000054006200000040005200000000630054006460000000000000000000006065005460650000004000520000000000005400646000000000000000000000006044476060606060500055000000000000540000000000000000000000000000000000000000000000000000000000000000
0000000000006060606000000000000052000000000050005300000000000052000000000000606060600000000000005200000000005000530062000000005200000000000060606060000000000000520000000000201621006200000018520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000053000000630054005200006460606052000000000000000000000000000000005300006300005400520000000000445900000000000000000000000000000000530062000000546054000000000044590000000000000000002700000000000000000000000000000000000000000000
0000000000000000005400000000000052100000000052005300000000000051000000000000000000540000000000005200000000005200530000000000005100000000000000000054000000000000520000000000520053000000000000510000000000000000005400000000000000000000000000000000000000000000
0000000000005400005300005400000055606060650053005500620000000055000000000000540000530000540000005500620000005300550000630000005500000000000054000053000054000000510000006300530052000063000000550000000000005400005300005400000000000000000000000000000000000000
0000005400005200005200005300000020000000000051172100000000000050000000540000520000520000530000002100000000005117210000000000005000000054000052000052000053000000530000170000510051000000000000500000005400005200005200005300000000000000000000000000000000000000
4044424849435a45464849435a424540545050404449484149454649434750404044424849435a45464849435a424540545050404449484149454649434750404044424849435a45464849435a42454052505040444948415a454649434750404044424849435a45464849435a42454054505040444943414945464243475040
4040504055405642574055505540504448424345405540444842575040564540404050405540564257405550554050444842434540554044484257504056454040405040554056425740555055405044484243454055404448425750405645404040504055405642574055505540504448424345405540444842575040564540
__sfx__
0101000015050180501a0501d05020050220502304018040220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000180501f0501f0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001805008050080500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000180501f050240502700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000180501f0501c050240501f0501c0501805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
