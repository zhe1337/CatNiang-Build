package dev.BULLWW.mod.modules.impl.combat;

import dev.BULLWW.mod.modules.Module;
import dev.BULLWW.mod.modules.Module$Category;
import dev.BULLWW.mod.modules.settings.impl.BooleanSetting;
import dev.BULLWW.mod.modules.settings.impl.SliderSetting;
import dev.BULLWW.api.utils.math.Timer;
import dev.BULLWW.api.utils.player.EntityUtil;
import dev.BULLWW.api.utils.player.InventoryUtil;
import dev.BULLWW.api.utils.world.BlockUtil;
import dev.BULLWW.api.events.impl.ClientTickEvent;
import net.minecraft.class_1297;
import net.minecraft.class_1268;
import net.minecraft.class_1657;
import net.minecraft.class_1792;
import net.minecraft.class_1799;
import net.minecraft.class_1802;
import net.minecraft.class_1923;
import net.minecraft.class_2248;
import net.minecraft.class_2338;
import net.minecraft.class_2350;
import net.minecraft.class_238;
import net.minecraft.class_243;
import net.minecraft.class_2680;
import net.minecraft.class_310;
import net.minecraft.class_4587;
import net.minecraft.class_4970;
import net.minecraft.class_5002;
import net.minecraft.class_746;
import net.minecraft.class_7980;
import net.minecraft.class_7981;
import net.minecraft.class_7982;
import net.minecraft.class_7983;
import net.minecraft.class_2824;
import net.minecraft.class_1511;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class PistonCrystalPlus extends Module {

    private final BooleanSetting fire = add(new BooleanSetting("Fire", true));
    private final SliderSetting range = add(new SliderSetting("Range", 5.0, 1.0, 6.0));
    private final SliderSetting delay = add(new SliderSetting("Delay", 50, 0, 500));
    private final Timer timer = new Timer();
    public class_1657 target;

    public PistonCrystalPlus() {
        super("PistonCrystal+", "Places piston + redstone + crystal to push crystal into target", Module$Category.Combat);
        this.setChinese("活塞水晶+");
    }

    @Override
    public void onEnable() {
        timer.reset();
    }

    @Override
    public void onTick(ClientTickEvent event) {
        if (Module.nullCheck()) {
            return;
        }
        target = getTarget(range.getValue());
        if (target != null) {
            int redBlock = InventoryUtil.findBlock(net.minecraft.class_2248.class_2250.field_10489);
            int piston = InventoryUtil.findItem(net.minecraft.class_1792.field_10743);
            int crystal = InventoryUtil.findItem(net.minecraft.class_1792.field_8165);
            
            if (redBlock != -1 && piston != -1 && crystal != -1) {
                class_2338 enemyPos = EntityUtil.getEntityPos(target);
                class_2248 blockAtEnemy = BlockUtil.getBlock(enemyPos);
                if (blockAtEnemy == net.minecraft.class_2248.class_2250.field_10124) {
                    if (timer.passedMs((long) delay.getValue().intValue())) {
                        class_2350[] directions = {class_2350.field_11036, class_2350.field_11043, class_2350.field_11029, class_2350.field_11022};
                        int[] pitches = {270, 90, 0, 180};
                        
                        for (int i = 0; i < 4; i++) {
                            class_2350 dir = directions[i];
                            class_2338 placePos = enemyPos.offset(dir);
                            if (placeCheck(placePos, dir)) {
                                if (isAir(placePos.up()) && isAir(placePos.up(2))) {
                                    place(placePos, dir, pitches[i]);
                                }
                                class_2338 pistonPos = getPiston(placePos, dir);
                                if (pistonPos != null) {
                                    activatePiston(pistonPos);
                                }
                                break;
                            }
                        }
                        
                        class_2338 headPos = enemyPos.up();
                        for (int i = 0; i < 4; i++) {
                            class_2350 dir = directions[i];
                            class_2338 placePos = headPos.offset(dir);
                            if (placeCheck(placePos, dir) && checkDamage(enemyPos.up())) {
                                if (isAir(placePos.up()) && isAir(placePos.up(2))) {
                                    place(placePos, dir, pitches[i]);
                                }
                                class_2338 pistonPos = getPiston(placePos, dir);
                                if (pistonPos != null) {
                                    activatePiston(pistonPos);
                                }
                                break;
                            }
                        }
                        
                        breakCrystal();
                        timer.reset();
                    }
                }
            } else {
                sendMessage("§cNo Redstone Block or Piston or Crystal!");
                disable();
            }
        }
    }

    private void breakCrystal() {
        List<class_1511> crystals = mc.field_1687.getEntities().stream()
            .filter(e -> e instanceof class_1511 && !e.removed)
            .sorted(Comparator.comparing(e -> mc.player.squaredDistanceTo(e)))
            .collect(Collectors.toList());
        
        for (class_1511 crystal : crystals) {
            if (!(crystal.squaredDistanceTo(target) > 6.25)) {
                attackEntity(crystal);
            }
        }
    }

    private void attackEntity(class_1511 crystal) {
        class_2824 packet = new class_2824(class_2824.class_5907.field_29011, crystal.getId(), mc.player.getYaw(), mc.player.getPitch());
        mc.getNetworkHandler().sendPacket(packet);
        EntityUtil.swingHand(class_1268.field_5808, dev.BULLWW.mod.modules.settings.enums.SwingSide.SERVER);
    }

    private boolean placeCheck(class_2338 pos, class_2350 dir) {
        return canPlaceCrystal(pos)
            && getPiston(pos, dir) != null
            && getRedStone(getPiston(pos, dir), dir) != null
            && checkDistance(getPiston(pos, dir));
    }

    private void place(class_2338 crystalPos, class_2350 dir, int pitch) {
        class_2338 redstonePos = getRedStone(getPiston(crystalPos, dir), dir);
        class_2338 pistonPos = getPiston(crystalPos, dir);
        if (redstonePos != null && pistonPos != null) {
            placeBlocks(redstonePos, pistonPos, pitch, crystalPos);
            
            if (fire.getValue()) {
                placeFire(crystalPos.up());
            }
        }
    }

    private class_1657 getTarget(double range) {
        class_1657 target = null;
        double distance = range;

        for (class_1657 player : mc.field_1687.getPlayers()) {
            if (isValidTarget(player, range) && (target == null || !(mc.player.squaredDistanceTo(player) >= distance * distance))) {
                target = player;
                distance = mc.player.distanceTo(player);
            }
        }
        return target;
    }

    private boolean isValidTarget(class_1657 player, double range) {
        return player != mc.player
            && !player.removed
            && player.isAlive()
            && !player.isSpectator()
            && mc.player.squaredDistanceTo(player) <= range * range;
    }

    private boolean canPlaceCrystal(class_2338 pos) {
        return BlockUtil.canPlaceCrystal(pos);
    }

    private class_2338 getPiston(class_2338 crystalPos, class_2350 dir) {
        class_2350 pistonFacing = dir.getOpposite();
        class_2338 pistonPos = crystalPos.offset(pistonFacing);
        
        if (BlockUtil.canPlace(pistonPos) && !BlockUtil.hasEntity(new class_238(pistonPos), false)) {
            return pistonPos;
        }
        return null;
    }

    private class_2338 getRedStone(class_2338 pistonPos, class_2350 dir) {
        class_2338 redstonePos = pistonPos.offset(dir.getOpposite());
        if (BlockUtil.canPlace(redstonePos) && !BlockUtil.hasEntity(new class_238(redstonePos), false)) {
            return redstonePos;
        }
        return null;
    }

    private boolean checkDistance(class_2338 pos) {
        return mc.player.squaredDistanceTo(pos.toCenterPos()) <= range.getValue() * range.getValue();
    }

    private void placeBlocks(class_2338 redstonePos, class_2338 pistonPos, int pitch, class_2338 crystalPos) {
        InventoryUtil.switchToSlot(findRedstoneSlot());
        BlockUtil.placeBlock(redstonePos, true);
        
        InventoryUtil.switchToSlot(findPistonSlot());
        BlockUtil.placeBlock(pistonPos, true);
        
        InventoryUtil.switchToSlot(findCrystalSlot());
        BlockUtil.placeBlock(crystalPos, true);
    }

    private void placeFire(class_2338 pos) {
        int flintSteel = InventoryUtil.findItem(net.minecraft.class_1792.field_11678);
        if (flintSteel != -1) {
            InventoryUtil.switchToSlot(flintSteel);
            BlockUtil.placeBlock(pos, true);
        }
    }

    private void activatePiston(class_2338 pistonPos) {
        class_2350 facing = mc.world.getBlockState(pistonPos).get(class_4970.field_23165).getOpposite();
        BlockUtil.clickBlock(pistonPos, facing, true);
    }

    private boolean checkDamage(class_2338 pos) {
        return target.squaredDistanceTo(pos.toCenterPos()) <= 12.25;
    }

    private boolean isAir(class_2338 pos) {
        return BlockUtil.getBlock(pos) == net.minecraft.class_2248.class_2250.field_10124;
    }

    private int findRedstoneSlot() {
        return InventoryUtil.findBlock(net.minecraft.class_2248.class_2250.field_10489);
    }

    private int findPistonSlot() {
        return InventoryUtil.findItem(net.minecraft.class_1792.field_10743);
    }

    private int findCrystalSlot() {
        return InventoryUtil.findItem(net.minecraft.class_1792.field_8165);
    }
}
