-- author: Furkan Cayci, 2018
-- description: object buffer that holds the objects to display
--    object locations can be controlled from upper level
--    example contains a wall, a rectanble box and a round ball

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity displaybuffer is
    generic (
        OBJECT_SIZE : natural := 16;
        PIXEL_SIZE : natural := 24;
        RES_X : natural := 1280;
        RES_Y : natural := 720
    );
    port (
        video_active       : in  std_logic;
        pixel_x, pixel_y   : in  std_logic_vector(OBJECT_SIZE-1 downto 0);
        object1x, object1y : in  std_logic_vector(OBJECT_SIZE-1 downto 0);
        object2x, object2y : in  std_logic_vector(OBJECT_SIZE-1 downto 0);
        backgrnd_rgb       : in  std_logic_vector(PIXEL_SIZE-1 downto 0);
        rgb                : out std_logic_vector(PIXEL_SIZE-1 downto 0);
        -- BRAM Ports
        bram_addrb          : out std_logic_vector(0 to 31);
        bram_doutb          : in  std_logic_vector(0 to 31);
        bram_wenb           : out std_logic_vector(0 to 3);
        bram_dinb           : out std_logic_vector(0 to 31);
        bram_rstb           : out std_logic;
        bram_enb            : out std_logic
    );
end displaybuffer;

architecture rtl of displaybuffer is
    -- create a 4 pixel vertical wall
    constant WALL_X_L: integer := 420;
    constant WALL_X_R: integer := 424;
    
    -- create a 4 pixel vertical wall
    constant WALL2_X_L: integer := 844;
    constant WALL2_X_R: integer := 848;

    -- 1st object is a vertical box 48x8 pixel
    constant BOX_SIZE_X: integer :=  8;
    constant BOX_SIZE_Y: integer := 48;
    -- x, y coordinates of the box
    signal box_x_l : unsigned (OBJECT_SIZE-1 downto 0);
    signal box_y_t : unsigned (OBJECT_SIZE-1 downto 0);
    signal box_x_r : unsigned (OBJECT_SIZE-1 downto 0);
    signal box_y_b : unsigned (OBJECT_SIZE-1 downto 0);

    -- 2nd object is a ball
    constant BALL_SIZE: integer:=42;
    
    -- x, y coordinates of the ball
    signal ball_x_l : unsigned(OBJECT_SIZE-1 downto 0);
    signal ball_y_t : unsigned(OBJECT_SIZE-1 downto 0);
    signal ball_x_r : unsigned(OBJECT_SIZE-1 downto 0);
    signal ball_y_b : unsigned(OBJECT_SIZE-1 downto 0);

    -- signals that holds the x, y coordinates
    signal pix_x, pix_y, px: unsigned (OBJECT_SIZE-1 downto 0);

    signal wall_on, wall2_on, box_on, cube_on, square_ball_on, ball_on: std_logic;
    signal wall_rgb, wall2_rgb, box_rgb, ball_rgb, cube_rgb: std_logic_vector(23 downto 0);
    
    signal bram_data_buffer : std_logic_vector(0 to 31);
    signal bram_addr_buffer : std_logic_vector(0 to 31);
    signal bram_addr_buffer_i : integer :=0;
    

begin

    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

    bram_wenb <= (others => '0');  -- Always disable writing, only c can write to the bram
    bram_rstb <= '0';              -- Always disable reset
    bram_dinb <= (others => '0');  -- Nothing to write from here

    -- Enable bram when in the active area
    bram_enb <= '1' when video_active = '1' else '0';
    --bram_enb <= '1' ;

    -- Active bram addresses : BRAM_Addr(16:29) for 16KB BRAM (DS444)
    -- row start addres
    bram_addr_buffer <= x"000002A8" when pix_x>=928 and pix_x<970  and pix_y>84  and pix_y<=126 else --00
                        x"000002AC" when pix_x>=970 and pix_x<1012 and pix_y>84  and pix_y<=126 else --01
                        x"000002B0" when pix_x>=928 and pix_x<970  and pix_y>126 and pix_y<=168 else --10
                        x"000002B4" when pix_x>=970 and pix_x<1012 and pix_y>126 and pix_y<=168 else --11
                        x"000002B8" when pix_x>=928 and pix_x<970  and pix_y>168 and pix_y<=210 else --20
                        x"000002BC" when pix_x>=970 and pix_x<1012 and pix_y>168 and pix_y<=210 else --21
                        x"000002C0" when pix_x>=928 and pix_x<970  and pix_y>210 and pix_y<=252 else --30
                        x"000002C4" when pix_x>=970 and pix_x<1012 and pix_y>210 and pix_y<=252 else --31
                        
                        x"00000000" when pix_x>=424 and pix_x<466 and pix_y>678 and pix_y<=720 else --00
                        x"00000028" when pix_x>=424 and pix_x<466 and pix_y>636 and pix_y<=678 else --10
                        x"00000050" when pix_x>=424 and pix_x<466 and pix_y>594 and pix_y<=636 else --20
                        x"00000078" when pix_x>=424 and pix_x<466 and pix_y>552 and pix_y<=594 else --30
                        x"000000A0" when pix_x>=424 and pix_x<466 and pix_y>510 and pix_y<=552 else --40
                        x"000000C8" when pix_x>=424 and pix_x<466 and pix_y>468 and pix_y<=510 else --50
                        x"000000F0" when pix_x>=424 and pix_x<466 and pix_y>426 and pix_y<=468 else --60
                        x"00000118" when pix_x>=424 and pix_x<466 and pix_y>384 and pix_y<=426 else --70
                        x"00000140" when pix_x>=424 and pix_x<466 and pix_y>342 and pix_y<=384 else --80
                        x"00000168" when pix_x>=424 and pix_x<466 and pix_y>300 and pix_y<=342 else --90
                        x"00000190" when pix_x>=424 and pix_x<466 and pix_y>258 and pix_y<=300 else --100
                        x"000001B8" when pix_x>=424 and pix_x<466 and pix_y>216 and pix_y<=258 else --110
                        x"000001E0" when pix_x>=424 and pix_x<466 and pix_y>174 and pix_y<=216 else --120
                        x"00000208" when pix_x>=424 and pix_x<466 and pix_y>132 and pix_y<=174 else --130
                        x"00000230" when pix_x>=424 and pix_x<466 and pix_y>90  and pix_y<=132 else --140
                        x"00000258" when pix_x>=424 and pix_x<466 and pix_y>48  and pix_y<=90  else --150
                        x"00000280" when pix_x>=424 and pix_x<466 and pix_y>6   and pix_y<=48  else --160
                        
                        x"00000004" when pix_x>=466 and pix_x<508 and pix_y>678 and pix_y<=720 else --01
                        x"00000008" when pix_x>=508 and pix_x<550 and pix_y>678 and pix_y<=720 else --02
                        x"0000000C" when pix_x>=550 and pix_x<592 and pix_y>678 and pix_y<=720 else --03
                        x"00000010" when pix_x>=592 and pix_x<634 and pix_y>678 and pix_y<=720 else --04
                        x"00000014" when pix_x>=634 and pix_x<676 and pix_y>678 and pix_y<=720 else --05
                        x"00000018" when pix_x>=676 and pix_x<718 and pix_y>678 and pix_y<=720 else --06
                        x"0000001C" when pix_x>=718 and pix_x<760 and pix_y>678 and pix_y<=720 else --07
                        x"00000020" when pix_x>=760 and pix_x<802 and pix_y>678 and pix_y<=720 else --08
                        x"00000024" when pix_x>=802 and pix_x<844 and pix_y>678 and pix_y<=720 else --09
                        
                        x"0000002C" when pix_x>=466 and pix_x<508 and pix_y>636 and pix_y<=678 else --11
                        x"0000002C" when pix_x>=508 and pix_x<550 and pix_y>636 and pix_y<=678 else --12
                        x"00000034" when pix_x>=550 and pix_x<592 and pix_y>636 and pix_y<=678 else --13
                        x"00000038" when pix_x>=592 and pix_x<634 and pix_y>636 and pix_y<=678 else --14
                        x"0000003C" when pix_x>=634 and pix_x<676 and pix_y>636 and pix_y<=678 else --15
                        x"00000040" when pix_x>=676 and pix_x<718 and pix_y>636 and pix_y<=678 else --16
                        x"00000044" when pix_x>=718 and pix_x<760 and pix_y>636 and pix_y<=678 else --17
                        x"00000048" when pix_x>=760 and pix_x<802 and pix_y>636 and pix_y<=678 else --18
                        x"0000004C" when pix_x>=802 and pix_x<844 and pix_y>636 and pix_y<=678 else --19
                        
                        x"00000054" when pix_x>=466 and pix_x<508 and pix_y>594 and pix_y<=636 else --21
                        x"00000058" when pix_x>=508 and pix_x<550 and pix_y>594 and pix_y<=636 else --22
                        x"0000005C" when pix_x>=550 and pix_x<592 and pix_y>594 and pix_y<=636 else --23
                        x"00000060" when pix_x>=592 and pix_x<634 and pix_y>594 and pix_y<=636 else --24
                        x"00000064" when pix_x>=634 and pix_x<676 and pix_y>594 and pix_y<=636 else --25
                        x"00000068" when pix_x>=676 and pix_x<718 and pix_y>594 and pix_y<=636 else --26
                        x"0000006C" when pix_x>=718 and pix_x<760 and pix_y>594 and pix_y<=636 else --27
                        x"00000070" when pix_x>=760 and pix_x<802 and pix_y>594 and pix_y<=636 else --28
                        x"00000074" when pix_x>=802 and pix_x<844 and pix_y>594 and pix_y<=636 else --29
                        
                        x"0000007C" when pix_x>=466 and pix_x<508 and pix_y>552 and pix_y<=594 else --31
                        x"00000080" when pix_x>=508 and pix_x<550 and pix_y>552 and pix_y<=594 else --32
                        x"00000084" when pix_x>=550 and pix_x<592 and pix_y>552 and pix_y<=594 else --33
                        x"00000088" when pix_x>=592 and pix_x<634 and pix_y>552 and pix_y<=594 else --34
                        x"0000008C" when pix_x>=634 and pix_x<676 and pix_y>552 and pix_y<=594 else --35
                        x"00000090" when pix_x>=676 and pix_x<718 and pix_y>552 and pix_y<=594 else --36
                        x"00000094" when pix_x>=718 and pix_x<760 and pix_y>552 and pix_y<=594 else --37
                        x"00000098" when pix_x>=760 and pix_x<802 and pix_y>552 and pix_y<=594 else --38
                        x"0000009C" when pix_x>=802 and pix_x<844 and pix_y>552 and pix_y<=594 else --39
                        
                        x"000000A4" when pix_x>=466 and pix_x<508 and pix_y>510 and pix_y<=552 else --41
                        x"000000A8" when pix_x>=508 and pix_x<550 and pix_y>510 and pix_y<=552 else --42
                        x"000000AC" when pix_x>=550 and pix_x<592 and pix_y>510 and pix_y<=552 else --43
                        x"000000B0" when pix_x>=592 and pix_x<634 and pix_y>510 and pix_y<=552 else --44
                        x"000000B4" when pix_x>=634 and pix_x<676 and pix_y>510 and pix_y<=552 else --45
                        x"000000B8" when pix_x>=676 and pix_x<718 and pix_y>510 and pix_y<=552 else --46
                        x"000000BC" when pix_x>=718 and pix_x<760 and pix_y>510 and pix_y<=552 else --47
                        x"000000C0" when pix_x>=760 and pix_x<802 and pix_y>510 and pix_y<=552 else --48
                        x"000000C4" when pix_x>=802 and pix_x<844 and pix_y>510 and pix_y<=552 else --49
                        
                        x"000000CC" when pix_x>=466 and pix_x<508 and pix_y>468 and pix_y<=510 else --51
                        x"000000D0" when pix_x>=508 and pix_x<550 and pix_y>468 and pix_y<=510 else --52
                        x"000000D4" when pix_x>=550 and pix_x<592 and pix_y>468 and pix_y<=510 else --53
                        x"000000D8" when pix_x>=592 and pix_x<634 and pix_y>468 and pix_y<=510 else --54
                        x"000000DC" when pix_x>=634 and pix_x<676 and pix_y>468 and pix_y<=510 else --55
                        x"000000E0" when pix_x>=676 and pix_x<718 and pix_y>468 and pix_y<=510 else --56
                        x"000000E4" when pix_x>=718 and pix_x<760 and pix_y>468 and pix_y<=510 else --57
                        x"000000E8" when pix_x>=760 and pix_x<802 and pix_y>468 and pix_y<=510 else --58
                        x"000000EC" when pix_x>=802 and pix_x<844 and pix_y>468 and pix_y<=510 else --59
                        
                        x"000000F4" when pix_x>=466 and pix_x<508 and pix_y>426 and pix_y<=468 else --61
                        x"000000F8" when pix_x>=508 and pix_x<550 and pix_y>426 and pix_y<=468 else --62
                        x"000000FC" when pix_x>=550 and pix_x<592 and pix_y>426 and pix_y<=468 else --63
                        x"00000100" when pix_x>=592 and pix_x<634 and pix_y>426 and pix_y<=468 else --64
                        x"00000104" when pix_x>=634 and pix_x<676 and pix_y>426 and pix_y<=468 else --65
                        x"00000108" when pix_x>=676 and pix_x<718 and pix_y>426 and pix_y<=468 else --66
                        x"0000010C" when pix_x>=718 and pix_x<760 and pix_y>426 and pix_y<=468 else --67
                        x"00000110" when pix_x>=760 and pix_x<802 and pix_y>426 and pix_y<=468 else --68
                        x"00000114" when pix_x>=802 and pix_x<844 and pix_y>426 and pix_y<=468 else --69
                        
                        x"0000011C" when pix_x>=466 and pix_x<508 and pix_y>384 and pix_y<=426 else --71
                        x"00000120" when pix_x>=508 and pix_x<550 and pix_y>384 and pix_y<=426 else --72
                        x"00000124" when pix_x>=550 and pix_x<592 and pix_y>384 and pix_y<=426 else --73
                        x"00000128" when pix_x>=592 and pix_x<634 and pix_y>384 and pix_y<=426 else --74
                        x"0000012C" when pix_x>=634 and pix_x<676 and pix_y>384 and pix_y<=426 else --75
                        x"00000130" when pix_x>=676 and pix_x<718 and pix_y>384 and pix_y<=426 else --76
                        x"00000134" when pix_x>=718 and pix_x<760 and pix_y>384 and pix_y<=426 else --77
                        x"00000138" when pix_x>=760 and pix_x<802 and pix_y>384 and pix_y<=426 else --78
                        x"0000013C" when pix_x>=802 and pix_x<844 and pix_y>384 and pix_y<=426 else --79
                        
                        x"00000144" when pix_x>=466 and pix_x<508 and pix_y>342 and pix_y<=384 else --81
                        x"00000148" when pix_x>=508 and pix_x<550 and pix_y>342 and pix_y<=384 else --82
                        x"0000014C" when pix_x>=550 and pix_x<592 and pix_y>342 and pix_y<=384 else --83
                        x"00000150" when pix_x>=592 and pix_x<634 and pix_y>342 and pix_y<=384 else --84
                        x"00000154" when pix_x>=634 and pix_x<676 and pix_y>342 and pix_y<=384 else --85
                        x"00000158" when pix_x>=676 and pix_x<718 and pix_y>342 and pix_y<=384 else --86
                        x"0000015C" when pix_x>=718 and pix_x<760 and pix_y>342 and pix_y<=384 else --87
                        x"00000160" when pix_x>=760 and pix_x<802 and pix_y>342 and pix_y<=384 else --88
                        x"00000164" when pix_x>=802 and pix_x<844 and pix_y>342 and pix_y<=384 else --89
                        
                        x"0000016C" when pix_x>=466 and pix_x<508 and pix_y>300 and pix_y<=342 else --91
                        x"00000170" when pix_x>=508 and pix_x<550 and pix_y>300 and pix_y<=342 else --92
                        x"00000174" when pix_x>=550 and pix_x<592 and pix_y>300 and pix_y<=342 else --93
                        x"00000178" when pix_x>=592 and pix_x<634 and pix_y>300 and pix_y<=342 else --94
                        x"0000017C" when pix_x>=634 and pix_x<676 and pix_y>300 and pix_y<=342 else --95
                        x"00000180" when pix_x>=676 and pix_x<718 and pix_y>300 and pix_y<=342 else --96
                        x"00000184" when pix_x>=718 and pix_x<760 and pix_y>300 and pix_y<=342 else --97
                        x"00000188" when pix_x>=760 and pix_x<802 and pix_y>300 and pix_y<=342 else --98
                        x"0000018C" when pix_x>=802 and pix_x<844 and pix_y>300 and pix_y<=342 else --99
                        
                        x"00000194" when pix_x>=466 and pix_x<508 and pix_y>258 and pix_y<=300 else --101
                        x"00000198" when pix_x>=508 and pix_x<550 and pix_y>258 and pix_y<=300 else --102
                        x"0000019C" when pix_x>=550 and pix_x<592 and pix_y>258 and pix_y<=300 else --103
                        x"000001A0" when pix_x>=592 and pix_x<634 and pix_y>258 and pix_y<=300 else --104
                        x"000001A4" when pix_x>=634 and pix_x<676 and pix_y>258 and pix_y<=300 else --105
                        x"000001A8" when pix_x>=676 and pix_x<718 and pix_y>258 and pix_y<=300 else --106
                        x"000001AC" when pix_x>=718 and pix_x<760 and pix_y>258 and pix_y<=300 else --107
                        x"000001B0" when pix_x>=760 and pix_x<802 and pix_y>258 and pix_y<=300 else --108
                        x"000001B4" when pix_x>=802 and pix_x<844 and pix_y>258 and pix_y<=300 else --109
                        
                        x"000001BC" when pix_x>=466 and pix_x<508 and pix_y>216 and pix_y<=258 else --111
                        x"000001C0" when pix_x>=508 and pix_x<550 and pix_y>216 and pix_y<=258 else --112
                        x"000001C4" when pix_x>=550 and pix_x<592 and pix_y>216 and pix_y<=258 else --113
                        x"000001C8" when pix_x>=592 and pix_x<634 and pix_y>216 and pix_y<=258 else --114
                        x"000001CC" when pix_x>=634 and pix_x<676 and pix_y>216 and pix_y<=258 else --115
                        x"000001D0" when pix_x>=676 and pix_x<718 and pix_y>216 and pix_y<=258 else --116
                        x"000001D4" when pix_x>=718 and pix_x<760 and pix_y>216 and pix_y<=258 else --117
                        x"000001D8" when pix_x>=760 and pix_x<802 and pix_y>216 and pix_y<=258 else --118
                        x"000001DC" when pix_x>=802 and pix_x<844 and pix_y>216 and pix_y<=258 else --119
                        
                        x"000001E4" when pix_x>=466 and pix_x<508 and pix_y>174 and pix_y<=216 else --121
                        x"000001E8" when pix_x>=508 and pix_x<550 and pix_y>174 and pix_y<=216 else --122
                        x"000001EC" when pix_x>=550 and pix_x<592 and pix_y>174 and pix_y<=216 else --123
                        x"000001F0" when pix_x>=592 and pix_x<634 and pix_y>174 and pix_y<=216 else --124
                        x"000001F4" when pix_x>=634 and pix_x<676 and pix_y>174 and pix_y<=216 else --125
                        x"000001F8" when pix_x>=676 and pix_x<718 and pix_y>174 and pix_y<=216 else --126
                        x"000001FC" when pix_x>=718 and pix_x<760 and pix_y>174 and pix_y<=216 else --127
                        x"00000200" when pix_x>=760 and pix_x<802 and pix_y>174 and pix_y<=216 else --128
                        x"00000204" when pix_x>=802 and pix_x<844 and pix_y>174 and pix_y<=216 else --129
                        
                        x"0000020C" when pix_x>=466 and pix_x<508 and pix_y>132 and pix_y<=174 else --131
                        x"00000210" when pix_x>=508 and pix_x<550 and pix_y>132 and pix_y<=174 else --132
                        x"00000214" when pix_x>=550 and pix_x<592 and pix_y>132 and pix_y<=174 else --133
                        x"00000218" when pix_x>=592 and pix_x<634 and pix_y>132 and pix_y<=174 else --134
                        x"0000021C" when pix_x>=634 and pix_x<676 and pix_y>132 and pix_y<=174 else --135
                        x"00000220" when pix_x>=676 and pix_x<718 and pix_y>132 and pix_y<=174 else --136
                        x"00000224" when pix_x>=718 and pix_x<760 and pix_y>132 and pix_y<=174 else --137
                        x"00000228" when pix_x>=760 and pix_x<802 and pix_y>132 and pix_y<=174 else --138
                        x"0000022C" when pix_x>=802 and pix_x<844 and pix_y>132 and pix_y<=174 else --139
                        
                        x"00000234" when pix_x>=466 and pix_x<508 and pix_y>90  and pix_y<=132 else --141
                        x"00000238" when pix_x>=508 and pix_x<550 and pix_y>90  and pix_y<=132 else --142
                        x"0000023C" when pix_x>=550 and pix_x<592 and pix_y>90  and pix_y<=132 else --143
                        x"00000240" when pix_x>=592 and pix_x<634 and pix_y>90  and pix_y<=132 else --144
                        x"00000244" when pix_x>=634 and pix_x<676 and pix_y>90  and pix_y<=132 else --145
                        x"00000248" when pix_x>=676 and pix_x<718 and pix_y>90  and pix_y<=132 else --146
                        x"0000024C" when pix_x>=718 and pix_x<760 and pix_y>90  and pix_y<=132 else --147
                        x"00000250" when pix_x>=760 and pix_x<802 and pix_y>90  and pix_y<=132 else --148
                        x"00000254" when pix_x>=802 and pix_x<844 and pix_y>90  and pix_y<=132 else --149
                        
                        x"0000025C" when pix_x>=466 and pix_x<508 and pix_y>48  and pix_y<=90  else --151
                        x"00000260" when pix_x>=508 and pix_x<550 and pix_y>48  and pix_y<=90  else --152
                        x"00000264" when pix_x>=550 and pix_x<592 and pix_y>48  and pix_y<=90  else --153
                        x"00000268" when pix_x>=592 and pix_x<634 and pix_y>48  and pix_y<=90  else --154
                        x"0000026C" when pix_x>=634 and pix_x<676 and pix_y>48  and pix_y<=90  else --155
                        x"00000270" when pix_x>=676 and pix_x<718 and pix_y>48  and pix_y<=90  else --156
                        x"00000274" when pix_x>=718 and pix_x<760 and pix_y>48  and pix_y<=90  else --157
                        x"00000278" when pix_x>=760 and pix_x<802 and pix_y>48  and pix_y<=90  else --158
                        x"0000027C" when pix_x>=802 and pix_x<844 and pix_y>48  and pix_y<=90  else --159
                        
                        x"00000284" when pix_x>=466 and pix_x<508 and pix_y>6   and pix_y<=48  else --161
                        x"00000288" when pix_x>=508 and pix_x<550 and pix_y>6   and pix_y<=48  else --162
                        x"0000028C" when pix_x>=550 and pix_x<592 and pix_y>6   and pix_y<=48  else --163
                        x"00000290" when pix_x>=592 and pix_x<634 and pix_y>6   and pix_y<=48  else --164
                        x"00000294" when pix_x>=634 and pix_x<676 and pix_y>6   and pix_y<=48  else --165
                        x"00000298" when pix_x>=676 and pix_x<718 and pix_y>6   and pix_y<=48  else --166
                        x"0000029C" when pix_x>=718 and pix_x<760 and pix_y>6   and pix_y<=48  else --167
                        x"000002A0" when pix_x>=760 and pix_x<802 and pix_y>6   and pix_y<=48  else --168
                        x"000002A4" when pix_x>=802 and pix_x<844 and pix_y>6   and pix_y<=48  else --169
                        x"00000400"; 

    --std_logic_vector(TO_UNSIGNED((bram_addr_buffer_i + 4),32)) when pix_x>424 and pix_x<844 and pix_x mod 42 = 4
    --else bram_addr_buffer;
    
    -- Increment address 4 in every 42 pixel
    --bram_addr_buffer <= std_logic_vector(TO_UNSIGNED((bram_addr_buffer_i + 4),32)) 
    --                    when pix_x>424 and pix_x<844 and pix_x mod 42 = 4;
    
    --bram_addr_buffer_i <= to_integer(unsigned(bram_addr_buffer));
    bram_addrb <= bram_addr_buffer;

    -- Get the data, 
    bram_data_buffer <= bram_doutb when video_active = '1' else (others => '0');
    
    --draw cubes and color
    cube_on <= '1' when bram_data_buffer(28 to 31) = x"A" or pix_y<=6 else '0';
    cube_rgb <= bram_data_buffer(0 to 23) when video_active = '1' and cube_on = '1' else (others => '0');
    --cube_rgb <= x"00FF00"; -- green

    -- draw wall and color
    wall_on <= '1' when WALL_X_L<=pix_x and pix_x<=WALL_X_R else '0';
    wall_rgb <= x"0000FF"; -- blue
    -- draw wall2 and color
    wall2_on <= '1' when WALL2_X_L<=pix_x and pix_x<=WALL2_X_R else '0';
    wall2_rgb <= x"0000FF"; -- blue

    -- draw box and color
    -- calculate the coordinates
    box_x_l <= unsigned(object1x);
    box_y_t <= unsigned(object1y);
    box_x_r <= box_x_l + BOX_SIZE_X - 1;
    box_y_b <= box_y_t + BOX_SIZE_Y - 1;
    
    box_on <= '1' when box_x_l<=pix_x and pix_x<=box_x_r and
                       box_y_t<=pix_y and pix_y<=box_y_b else
              '0';
    
    -- box rgb output
    box_rgb <= x"00FF00"; --green
    --box_rgb <= bram_doutb(0 to 23); --red
    --box_rgb <= bram_data_buffer(0 to 23); --red

    -- draw ball and color
    -- calculate the coordinates
    ball_x_l <= unsigned(object2x);
    ball_y_t <= unsigned(object2y);
    ball_x_r <= ball_x_l + BALL_SIZE - 1;
    ball_y_b <= ball_y_t + BALL_SIZE - 1;

    square_ball_on <= '1' when ball_x_l<=pix_x and pix_x<=ball_x_r and
                               ball_y_t<=pix_y and pix_y<=ball_y_b else
                      '0';
    -- pixel within ball
    ball_on <= '1' when square_ball_on='1' else '0';
    -- ball rgb output
    ball_rgb <= x"FF0000";   -- red
    --ball_rgb <= bram_doutb(0 to 23); -- red

    -- display the image based on who is active
    -- note that the order is important
    process(video_active, wall_on, box_on, wall_rgb, box_rgb, ball_rgb, backgrnd_rgb, ball_on, cube_on, bram_data_buffer) is
    begin
    
       if video_active='0' then
           rgb <= x"000000"; --blank
       else
          if wall_on='1' then
            rgb <= wall_rgb;
          elsif wall2_on='1' then
            rgb <= wall2_rgb;
          elsif ball_on='1' then
            rgb <= ball_rgb;
          elsif box_on='1' then
            rgb <= box_rgb;
          elsif cube_on='1' then
            rgb<= cube_rgb; 
          else
             rgb <= backgrnd_rgb; -- x"FFFF00"; -- yellow background
          end if;
       end if;
    end process;

end rtl;