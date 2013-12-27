--
-- another silly test system
--

local tbl = {}

function rotator_set(ent, speed)
    if not speed then speed = 2 * math.pi end
    tbl[ent] = speed
end

cgame.add_system('rotator',
{
    update_all = function (dt)
        for ent, speed in pairs(tbl) do
            cgame.transform_rotate(ent, speed * dt)
        end
    end,
})

return
{
    set = rotator_set,
}
