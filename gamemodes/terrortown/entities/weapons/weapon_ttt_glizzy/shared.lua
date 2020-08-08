-- TODO
-- [x] customize shootsound and supershootsound
-- [] add multiple sounds to randomize
-- [] customize battledeny sound


local ShootSound                =   Sound( "weapons/glizzy/glizzy.wav" )
local SuperShootSound           =   Sound( "weapons/glizzy/superglizzy.wav" )
local BattleCry                 =   Sound( "weapons/glizzy/go_viral_able.wav" )
local BattleDeny                =   Sound( "weapons/glock/glock_clipout.wav" ) 

if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("sound/weapons/glizzy/glizzy.wav")
   resource.AddFile("sound/weapons/glizzy/superglizzy.wav")
   resource.AddFile("sound/weapons/glizzy/go_viral_able.wav")
   resource.AddFile("materials/vgui/ttt/icon_glizzy.vmt")
end

SWEP.HoldType              = "pistol"

if CLIENT then
   SWEP.PrintName          =  "Glizzy"
   SWEP.Slot			   =  6

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 54

   SWEP.Icon               = "vgui/ttt/icon_glizzy"
   SWEP.IconLetter         = "c"
   
   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Why not both? \n\nDoes more damage up close. \nSecondary fire charges a shot with remaining ammo."
   };
end

SWEP.Base                  = "weapon_tttbase"

SWEP.AutoSpawnable         = true

SWEP.Kind                  = WEAPON_EQUIP1

SWEP.NoSights              = true 

SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }


--------------------------------------------------------

SWEP.Author                     =   "Yuler"

SWEP.Spawnable                  =   false
SWEP.AdminOnly                  =   false

SWEP.Primary.ClipSize           =   20
SWEP.Primary.DefaultClip	    =   20
SWEP.Primary.ClipMax            =   20
SWEP.Primary.Automatic		    =   false
-- SWEP.Primary.Delay              =   0.10
SWEP.Primary.Ammo		        =   "Glizzy"
SWEP.Primary.Recoil             =   2 -- The amount of recoil

SWEP.Secondary.ClipSize		    =   -1
SWEP.Secondary.DefaultClip	    =   -1
SWEP.Secondary.Automatic	    =   false
SWEP.Secondary.Ammo		        =   "none"

SWEP.Weight			            =   5
SWEP.AutoSwitchTo		        =   false
SWEP.AutoSwitchFrom		        =   false


SWEP.SlotPos			        =   7
SWEP.DrawAmmo			        =   true
SWEP.DrawCrosshair		        =   false
SWEP.CSMuzzleFlashes            =   true

SWEP.UseHands                   =   true
SWEP.ViewModel                  =   "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel                 =   "models/weapons/w_pist_glock18.mdl"

-- SWEP.IronSightsPos              =   Vector( -5.79, -3.9982, 2.8289 )

local supershot = false
local supercooldown = 2.4
local last_super = 0

--
-- Add hook to Initialize instead of overriding
--
local function init()
	print("Initialization hook called")
end
hook.Add( "Initialize", "some_unique_name", init )

--
-- Called when the left mouse button is pressed
--
function SWEP:PrimaryAttack() 
    if ( !self:CanPrimaryAttack() ) then return end
    
	-- Call 'ThrowGlizzy' on self with this model
    self:ThrowGlizzy( "models/food/hotdog.mdl" )
    supershot = false
end

--
-- Called when the rightmouse button is pressed
--
function SWEP:SecondaryAttack()
    if supershot then return end
    
    if self:Clip1() >= 1 then
        self:EmitSound( BattleCry )
        self.Weapon:SetNextPrimaryFire( CurTime() + 1.4 ) -- duration of battlecry
        supershot = true
        last_super = CurTime()
    else
        self:EmitSound( BattleDeny )
    end
    
end

function SWEP:Think() -- aka process() aka loop() aka update()
    if supershot and last_super < CurTime() - supercooldown then
        supershot = false
        self:EmitSound( BattleDeny )
    end
    
    -- self:NextThink( CurTime() ) -- Set the next think to run as soon as possible, i.e. the next frame.
	-- return true -- Apply NextThink call
end


--
-- A custom function we added. When you call this the player will fire a glizzy!
--
function SWEP:ThrowGlizzy( model_file )
    self:ShootEffects()
	-- 
	-- Play the shoot sound we precached earlier!
	--
    if supershot then
        self:EmitSound( SuperShootSound )
    else
        self:EmitSound( ShootSound )
    end
	

	--
	-- If we're the client then this is as much as we want to do.
	-- We play the sound above on the client due to prediction.
	-- ( if we didn't they would feel a ping delay during multiplayer )
	--
	if ( CLIENT ) then return end  ----------------------------------------------------------------------------


	-- Create a prop_physics entity
	local ent = ents.Create( "prop_physics" )

	-- Always make sure that created entities are actually created!
	if ( !IsValid( ent ) ) then return end

	-- Set the entity's model to the passed in model
	ent:SetModel( model_file )
 
	-- Set the position to the player's eye position.
	-- Set the angles to the player'e eye angles. Then spawn it.
	-- Probably a nicer way to do this with raycasting or something
	ent:SetPos( self.Owner:GetShootPos() - Vector(0,0,14) + (self.Owner:GetAimVector() * 1 ) )
	ent:SetAngles( self.Owner:EyeAngles() )
    
    ent:SetPhysicsAttacker( self.Owner, 5 ) -- Set killer as player for 5 seconds
    
	ent:Spawn()
    
    if supershot then -- glizzy confetti
        a = {}
        for i=1, self:Clip1() - 1 do
            a[i] = ents.Create( "prop_physics" )
            if ( !IsValid( a[i] ) ) then return end

            a[i]:SetModel( model_file )
         
            a[i]:SetPos( self.Owner:GetShootPos() - Vector(0,0,14) + (self.Owner:GetAimVector() * Vector( math.Rand(10,-10), math.Rand(10,-10), 0 ) ) )
            a[i]:SetAngles( self.Owner:EyeAngles() )
            
            a[i]:Spawn()
            
            local phys = a[i]:GetPhysicsObject()
            phys:SetMaterial( "watermelon" )
        end
    end

	-- Now get the physics object. Whenever we get a physics object
	-- we need to test to make sure its valid before using it.
	-- If it isn't then we'll remove the entity.
	local phys = ent:GetPhysicsObject()
	if ( !IsValid( phys ) ) then ent:Remove() return end
 
	-- Now we apply the force - so the glizzy actually throws instead 
	-- of just falling to the ground. You can play with this value here
	-- to adjust how fast we throw it.
	local force = self.Owner:GetAimVector()
    local velocity = 1825
    local recoil = self.Primary.Recoil
    local mass = 10 -- min mass that still allows water splash at reasonable angles
    
    if supershot then
        velocity = ( 10000/(20.0001-self:Clip1())) + 1300 -- visualize in desmos; self:Clip1() is x
        mass = ( 10/(20.245-self:Clip1()) - (1/2) ) + 10
        recoil = math.pow(self:Clip1(), 1.125) -- relative oomph
        self:TakePrimaryAmmo( self:Clip1() ) -- use rest of magazine
        ent:SetColor( Color( 64, 32, 32, 255 ) )
    else
        self:TakePrimaryAmmo(1)
    end
    
    print("Mass: " .. mass) -- .. is lua string concatenate
    print("Velocity: " .. velocity)
    print("Momentum: " .. mass * velocity)
    
    -- physical stuff
    force = force * velocity
	phys:ApplyForceCenter( force )
    phys:SetMass( mass ) -- set mass so it will do damage
    phys:SetBuoyancyRatio(7) -- to make glizzies float in water
    phys:SetMaterial("watermelon") -- for squishy impact sound
    
    -- Visual punch
    self.Owner:ViewPunch( Angle( util.SharedRandom(self:GetClass(),-0.2,-0.1,0) * recoil, util.SharedRandom(self:GetClass(),-0.1,0.1,1) * recoil, 0 ) )
    
    -- actual recoil changing aim angle
    local eyeang = self:GetOwner():EyeAngles()
    eyeang.pitch = eyeang.pitch - recoil
    self:GetOwner():SetEyeAngles( eyeang )

end