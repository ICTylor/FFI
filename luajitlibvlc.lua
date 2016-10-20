-- http://stackoverflow.com/questions/17987618/how-to-add-a-sleep-or-wait-to-my-lua-script
local ffi = require("ffi")
ffi.cdef[[
typedef struct libvlc_instance_t libvlc_instance_t;
typedef int64_t libvlc_time_t;
libvlc_instance_t * libvlc_new( int argc , const char *const *argv );
void libvlc_release( libvlc_instance_t *p_instance );
typedef struct libvlc_media_t libvlc_media_t;
typedef struct libvlc_media_player_t libvlc_media_player_t;
libvlc_media_t *libvlc_media_new_location(
                                   libvlc_instance_t *p_instance,
                                   const char * psz_mrl );
libvlc_media_t *libvlc_media_new_path(
                                   libvlc_instance_t *p_instance,
                                   const char *path );
libvlc_media_player_t * libvlc_media_player_new( libvlc_instance_t *p_libvlc_instance );
void libvlc_media_player_release( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_media( libvlc_media_player_t *p_mi,
                                                   libvlc_media_t *p_md );
void libvlc_media_player_stop ( libvlc_media_player_t *p_mi );
int libvlc_media_player_play ( libvlc_media_player_t *p_mi );
void libvlc_media_player_release( libvlc_media_player_t *p_mi );
int MessageBoxA(void *w, const char *txt, const char *cap, int type);
]]

ffi.cdef[[
void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

local sleep
if ffi.os == "Windows" then
  function sleep(s)
    ffi.C.Sleep(s*1000)
  end
else
  function sleep(s)
    ffi.C.poll(nil, 0, s*1000)
  end
end

local vlc = ffi.load("libvlc")
local vlc_instance = vlc.libvlc_new(0, nil)
local big_buck_bunny_url = "http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_480p_surround-fix.avi"
local media = vlc.libvlc_media_new_location(vlc_instance, big_buck_bunny_url)
local media_player = vlc.libvlc_media_player_new(vlc_instance)
vlc.libvlc_media_player_set_media(media_player,media)
vlc.libvlc_media_player_play(media_player)
sleep(10)
vlc.libvlc_media_player_stop(media_player)
vlc.libvlc_media_player_release(media_player)
vlc.libvlc_release(vlc_instance)
