/*
  Wearable chest sensor housing.
  Units: mm. Default: both halves side by side.
*/

$fn = 48;
eps = 0.05;

// Output
output_mode = "print_layout"; // "assembly", "exploded", "base", "lid", "print_layout", "fit_preview"
export_part = 0; // 0=mode, 1=base, 2=lid, 3=print, 4=fit, 5=exploded
selected_part = is_undef(preset_part) ? export_part : preset_part;
explode_gap = 14;
show_component_ghosts = true;

// Fit
wall = 2.40;
floor_thickness = 2.20;
lid_roof_thickness = 2.20;
corner_radius = 7.0;
fit_clearance = 0.35; // per side
vertical_clearance = 0.80;
solder_pin_protrusion = 3.0;
general_pcb_thickness = 1.60;
general_component_height = 4.20;

// Enclosure
case_size_xy = [85, 58];
base_inner_depth = 22.0;
top_board_stack = general_pcb_thickness
                + general_component_height
                + solder_pin_protrusion
                + vertical_clearance;
lid_inner_depth = max(10.0, top_board_stack + 0.5);

// Lid joint
joint_overlap = 4.0;
joint_step = 1.30;
joint_clearance = 0.25;

base_height = floor_thickness + base_inner_depth;
lid_height = lid_roof_thickness + lid_inner_depth + joint_overlap;

// Fasteners
use_screws = true;
use_snaps = false;
screw_positions = [
    [-14, -23.5], [13, -23.5]
];
screw_boss_od = 5.6;
screw_pilot_d = 1.70;
screw_clearance_d = 2.40;
screw_head_d = 4.40;
screw_head_recess = 1.10;
screw_engagement = 8.0;

snap_x_positions = [-20, 20];
snap_d = 2.0;
snap_protrusion = 0.55;
snap_recess_clearance = 0.25;

// Band
band_width = 25.0;
band_slot_length = band_width + 0.8;
band_slot_gap = 3.4; // strap thickness
band_lug_extension = 12.0;
band_lug_width = 34.0;
band_lug_thickness = 4.0;
band_lug_radius = 4.0;

// Bottom components
battery_size = [75.0, 21.5, 20.5];
battery_pos = [0, 14.3];
battery_rail = 1.20;
battery_rail_height = 4.0;

max30102_size = [14.0, 14.0, 1.60];
max30102_pos = [-30, -13.25];
max30102_component_height = 3.2;
max30102_standoff = 2.2;
max_sensor_window = [8.0, 8.0];

bms_size = [18.0, 23.6, 1.60];
bms_pos = [29, -13.25];
bms_component_height = 4.0;
bms_standoff = 2.0;
bms_usb_opening = [10.0, 5.2]; // [Y, Z]
bms_usb_z_offset = 0.6;

wire_slit_x = 0;
wire_slit_size = [5.0, 3.5]; // [X, Z]
wire_slit_z = floor_thickness + 0.5;

// Top components
esp32_size = [20.5, 25.0, 1.60];
esp32_pos = [-28, 0];
esp32_component_height = 4.2;
esp32_standoff = 1.6;
esp_screen_opening = [17.2, 14.0];
esp_screen_offset = [0, 0];
esp_usb_opening = [10.0, 5.2]; // [X, Z]
esp_usb_z_offset = 0.5;

sd_size = [17.9, 17.9, 1.60];
sd_pos = [-1, 0];
sd_component_height = 3.2;
sd_standoff = 1.6;
enable_sd_card_slot = true;
sd_card_slot = [19.0, 3.6]; // [X, Z]
sd_slot_z_offset = 0.3;

gsr_size = [25.0, 20.0, 1.60];
gsr_pos = [25.5, 0];
gsr_component_height = 3.0;
gsr_standoff = 1.6;
gsr_face_opening = [20.0, 20.0];
gsr_opening_corner_radius = 1.0;
gsr_mount_hole_spacing = 24.0;
gsr_mount_hole_diameter = 3.2;
enable_gsr_pin_row = false;
gsr_pin_count = 4;
gsr_pin_pitch = 2.54;
gsr_pin_diameter = 1.0;
gsr_pin_clearance = 0.45;
gsr_pin_row_offset = [0, 0];

// PCB cradle
pcb_rail = 1.20;
pcb_rail_above_board = 1.0;
pcb_corner_pad = 3.0;

// Geometry
module rounded_prism(size_xyz, radius) {
    rr = min(radius, min(size_xyz[0], size_xyz[1]) / 2 - 0.01);
    linear_extrude(height = size_xyz[2])
        offset(r = rr)
            square([size_xyz[0] - 2 * rr, size_xyz[1] - 2 * rr], center = true);
}

module centered_cube_xy(size_xyz) {
    translate([-size_xyz[0] / 2, -size_xyz[1] / 2, 0])
        cube(size_xyz);
}

module board_proxy(pos, size_xyz, z0, component_h, tint = [0.1, 0.55, 0.2, 0.55]) {
    color(tint)
        translate([pos[0], pos[1], z0])
            centered_cube_xy([size_xyz[0], size_xyz[1], size_xyz[2]]);
    color([0.75, 0.75, 0.78, 0.42])
        translate([pos[0], pos[1], z0 + size_xyz[2]])
            centered_cube_xy([size_xyz[0] * 0.72, size_xyz[1] * 0.68, component_h]);
}

// PCB supports
module pcb_cradle(pos, board_xy, z0, standoff, rail_above = pcb_rail_above_board) {
    env = [board_xy[0] + 2 * fit_clearance, board_xy[1] + 2 * fit_clearance];
    pad = min(pcb_corner_pad, min(board_xy[0], board_xy[1]) / 4);

    // Support pads
    for (sx = [-1, 1], sy = [-1, 1])
        translate([
            pos[0] + sx * (board_xy[0] / 2 - pad / 2),
            pos[1] + sy * (board_xy[1] / 2 - pad / 2),
            z0
        ])
            centered_cube_xy([pad, pad, standoff]);

    // Locating rails
    translate([pos[0], pos[1] - env[1] / 2 - pcb_rail / 2, z0])
        centered_cube_xy([env[0] + 2 * pcb_rail, pcb_rail, standoff + general_pcb_thickness + rail_above]);
    translate([pos[0], pos[1] + env[1] / 2 + pcb_rail / 2, z0])
        centered_cube_xy([env[0] + 2 * pcb_rail, pcb_rail, standoff + general_pcb_thickness + rail_above]);
    translate([pos[0] - env[0] / 2 - pcb_rail / 2, pos[1], z0])
        centered_cube_xy([pcb_rail, env[1], standoff + general_pcb_thickness + rail_above]);
    translate([pos[0] + env[0] / 2 + pcb_rail / 2, pos[1], z0])
        centered_cube_xy([pcb_rail, env[1], standoff + general_pcb_thickness + rail_above]);
}

module battery_cradle() {
    env_x = battery_size[0] + 2 * fit_clearance;
    env_y = battery_size[1] + 2 * fit_clearance;

    // Battery rails
    for (sy = [-1, 1])
        translate([
            battery_pos[0],
            battery_pos[1] + sy * (env_y / 2 + battery_rail / 2),
            floor_thickness - eps
        ])
            centered_cube_xy([env_x + 2 * battery_rail, battery_rail, battery_rail_height]);

    // Battery stops
    for (sx = [-1, 1])
        translate([
            battery_pos[0] + sx * (env_x / 2 + battery_rail / 2),
            battery_pos[1],
            floor_thickness - eps
        ])
            centered_cube_xy([battery_rail, env_y, battery_rail_height]);
}

// Band lugs
module band_lug_solids() {
    for (sx = [-1, 1])
        translate([
            sx * (case_size_xy[0] / 2 + band_lug_extension / 2 - 0.4),
            0,
            0
        ])
            rounded_prism(
                [band_lug_extension + 0.8, band_lug_width, band_lug_thickness],
                band_lug_radius
            );
}

module band_slot_cutouts() {
    for (sx = [-1, 1])
        translate([
            sx * (case_size_xy[0] / 2 + band_lug_extension / 2),
            0,
            -eps
        ])
            centered_cube_xy([band_slot_gap, band_slot_length, band_lug_thickness + 2 * eps]);
}

// Base
module base_shell() {
    inner_xy = [case_size_xy[0] - 2 * wall, case_size_xy[1] - 2 * wall];
    neck_xy = [case_size_xy[0] - 2 * joint_step, case_size_xy[1] - 2 * joint_step];

    difference() {
        union() {
            rounded_prism(
                [case_size_xy[0], case_size_xy[1], base_height - joint_overlap],
                corner_radius
            );
            translate([0, 0, base_height - joint_overlap - eps])
                rounded_prism(
                    [neck_xy[0], neck_xy[1], joint_overlap + eps],
                    max(1, corner_radius - joint_step)
                );
            band_lug_solids();
        }

        // Cavity
        translate([0, 0, floor_thickness])
            rounded_prism(
                [inner_xy[0], inner_xy[1], base_height - floor_thickness + eps],
                max(1, corner_radius - wall)
            );
    }
}

module base_screw_posts() {
    if (use_screws)
        for (p = screw_positions)
            translate([p[0], p[1], floor_thickness - eps])
                cylinder(d = screw_boss_od, h = base_height - floor_thickness + eps);
}

module base_snap_bumps() {
    if (use_snaps)
        for (px = snap_x_positions, sy = [-1, 1])
            translate([
                px,
                sy * (case_size_xy[1] / 2 - joint_step + snap_protrusion / 2),
                base_height - joint_overlap / 2
            ])
                rotate([90, 0, 0])
                    cylinder(d = snap_d, h = joint_step + snap_protrusion, center = true);
}

module base_opening_cutouts() {
    // Sensor window
    translate([max30102_pos[0], max30102_pos[1], -eps])
        centered_cube_xy([max_sensor_window[0], max_sensor_window[1], floor_thickness + 2 * eps]);

    // Wire slit
    translate([
        wire_slit_x,
        -case_size_xy[1] / 2 + wall / 2,
        wire_slit_z
    ])
        centered_cube_xy([wire_slit_size[0], wall + 2 * eps, wire_slit_size[1]]);

    // BMS USB-C
    bms_usb_z = floor_thickness + bms_standoff + bms_size[2]
              + bms_usb_opening[1] / 2 + bms_usb_z_offset;
    translate([
        case_size_xy[0] / 2 - wall / 2,
        bms_pos[1],
        bms_usb_z - bms_usb_opening[1] / 2
    ])
        centered_cube_xy([wall + 2 * eps, bms_usb_opening[0], bms_usb_opening[1]]);

    band_slot_cutouts();

    // Pilot holes
    if (use_screws)
        for (p = screw_positions)
            translate([p[0], p[1], base_height - screw_engagement])
                cylinder(d = screw_pilot_d, h = screw_engagement + eps);
}

module base_model() {
    difference() {
        union() {
            base_shell();
            battery_cradle();
            pcb_cradle(
                max30102_pos,
                [max30102_size[0], max30102_size[1]],
                floor_thickness - eps,
                max30102_standoff
            );
            pcb_cradle(
                bms_pos,
                [bms_size[0], bms_size[1]],
                floor_thickness - eps,
                bms_standoff
            );
            base_screw_posts();
            base_snap_bumps();
        }
        base_opening_cutouts();
    }
}

// Lid
module lid_shell() {
    main_inner_xy = [case_size_xy[0] - 2 * wall, case_size_xy[1] - 2 * wall];
    skirt_inner_xy = [
        case_size_xy[0] - 2 * joint_step + 2 * joint_clearance,
        case_size_xy[1] - 2 * joint_step + 2 * joint_clearance
    ];

    difference() {
        rounded_prism([case_size_xy[0], case_size_xy[1], lid_height], corner_radius);

        // Cavity
        translate([0, 0, lid_roof_thickness])
            rounded_prism(
                [
                    main_inner_xy[0],
                    main_inner_xy[1],
                    lid_height - joint_overlap - lid_roof_thickness + 2 * eps
                ],
                max(1, corner_radius - wall)
            );

        // Joint cavity
        translate([0, 0, lid_height - joint_overlap - eps])
            rounded_prism(
                [skirt_inner_xy[0], skirt_inner_xy[1], joint_overlap + 2 * eps],
                max(1, corner_radius - joint_step + joint_clearance)
            );
    }
}

module lid_screw_towers() {
    if (use_screws)
        for (p = screw_positions)
            translate([p[0], p[1], lid_roof_thickness - eps])
                cylinder(
                    d = screw_boss_od,
                    h = lid_height - joint_overlap - lid_roof_thickness + eps
                );
}

module lid_mounts() {
    pcb_cradle(
        esp32_pos,
        [esp32_size[0], esp32_size[1]],
        lid_roof_thickness - eps,
        esp32_standoff
    );
    pcb_cradle(
        sd_pos,
        [sd_size[0], sd_size[1]],
        lid_roof_thickness - eps,
        sd_standoff
    );
    pcb_cradle(
        gsr_pos,
        [gsr_size[0], gsr_size[1]],
        lid_roof_thickness - eps,
        gsr_standoff
    );
}

module lid_opening_cutouts() {
    // ESP32 screen
    translate([
        esp32_pos[0] + esp_screen_offset[0],
        esp32_pos[1] + esp_screen_offset[1],
        -eps
    ])
        rounded_prism(
            [esp_screen_opening[0], esp_screen_opening[1], lid_roof_thickness + 2 * eps],
            1.2
        );

    // ESP32 USB-C
    esp_usb_z = lid_roof_thickness + esp32_standoff + esp32_size[2]
              + esp_usb_opening[1] / 2 + esp_usb_z_offset;
    translate([
        esp32_pos[0],
        -case_size_xy[1] / 2 + wall / 2,
        esp_usb_z - esp_usb_opening[1] / 2
    ])
        centered_cube_xy([esp_usb_opening[0], wall + 2 * eps, esp_usb_opening[1]]);

    // SD card
    if (enable_sd_card_slot) {
        sd_z = lid_roof_thickness + sd_standoff + sd_size[2]
             + sd_card_slot[1] / 2 + sd_slot_z_offset;
        translate([
            sd_pos[0],
            case_size_xy[1] / 2 - wall / 2,
            sd_z - sd_card_slot[1] / 2
        ])
            centered_cube_xy([sd_card_slot[0], wall + 2 * eps, sd_card_slot[1]]);
    }

    // GSR connector opening
    translate([gsr_pos[0], gsr_pos[1], -eps])
        rounded_prism(
            [gsr_face_opening[0], gsr_face_opening[1], lid_roof_thickness + 2 * eps],
            gsr_opening_corner_radius
        );

    // GSR mounting holes
    for (sx = [-1, 1])
        translate([
            gsr_pos[0] + sx * gsr_mount_hole_spacing / 2,
            gsr_pos[1],
            -eps
        ])
            cylinder(
                d = gsr_mount_hole_diameter,
                h = lid_roof_thickness + 2 * eps
            );

    // Optional GSR pin holes
    if (enable_gsr_pin_row)
        for (i = [0 : gsr_pin_count - 1]) {
            pin_x = gsr_pos[0] + gsr_pin_row_offset[0]
                  + (i - (gsr_pin_count - 1) / 2) * gsr_pin_pitch;
            pin_y = gsr_pos[1] + gsr_pin_row_offset[1];
            translate([pin_x, pin_y, -eps])
                cylinder(
                    d = gsr_pin_diameter + 2 * gsr_pin_clearance,
                    h = lid_roof_thickness + 2 * eps
                );
        }

    // Screw holes
    if (use_screws)
        for (p = screw_positions) {
            translate([p[0], p[1], -eps])
                cylinder(
                    d = screw_clearance_d,
                    h = lid_height - joint_overlap + 2 * eps
                );
            translate([p[0], p[1], -eps])
                cylinder(d = screw_head_d, h = screw_head_recess + eps);
        }

    // Snap recesses
    if (use_snaps)
        for (px = snap_x_positions, sy = [-1, 1])
            translate([
                px,
                sy * (case_size_xy[1] / 2 - joint_step + joint_clearance / 2),
                lid_height - joint_overlap / 2
            ])
                rotate([90, 0, 0])
                    cylinder(
                        d = snap_d + 2 * snap_recess_clearance,
                        h = joint_step + joint_clearance + 2 * eps,
                        center = true
                    );
}

module lid_model() {
    difference() {
        union() {
            lid_shell();
            lid_mounts();
            lid_screw_towers();
        }
        lid_opening_cutouts();
    }
}

// Assembly transform
module lid_in_assembly(extra_z = 0) {
    translate([0, 0, base_height + lid_height - joint_overlap + extra_z])
        rotate([180, 0, 0])
            lid_model();
}

// Preview components
module base_component_ghosts() {
    color([0.15, 0.35, 0.9, 0.35])
        translate([battery_pos[0], battery_pos[1], floor_thickness + 0.1])
            centered_cube_xy(battery_size);

    board_proxy(
        max30102_pos,
        max30102_size,
        floor_thickness + max30102_standoff,
        max30102_component_height,
        [0.55, 0.15, 0.7, 0.55]
    );
    board_proxy(
        bms_pos,
        bms_size,
        floor_thickness + bms_standoff,
        bms_component_height,
        [0.15, 0.55, 0.2, 0.55]
    );
}

module lid_component_ghosts() {
    board_proxy(
        esp32_pos,
        esp32_size,
        lid_roof_thickness + esp32_standoff,
        esp32_component_height,
        [0.1, 0.35, 0.75, 0.55]
    );
    board_proxy(
        sd_pos,
        sd_size,
        lid_roof_thickness + sd_standoff,
        sd_component_height,
        [0.75, 0.25, 0.1, 0.55]
    );
    board_proxy(
        gsr_pos,
        gsr_size,
        lid_roof_thickness + gsr_standoff,
        gsr_component_height,
        [0.75, 0.65, 0.1, 0.55]
    );
}

// Checks
assert(wall > joint_step + 0.4, "wall must exceed joint_step by at least 0.4 mm");
assert(joint_step > joint_clearance + 0.5, "lid skirt is too thin for this joint clearance");
assert(base_inner_depth >= battery_size[2] + vertical_clearance,
       "Increase base_inner_depth for the battery holder");
assert(lid_inner_depth >= top_board_stack,
       "Increase lid_inner_depth or reduce the top board stack allowance");
assert(band_slot_length >= band_width,
       "band_slot_length must be at least the band width");

echo("Base external height", base_height);
echo("Lid external height incl. overlap", lid_height);
echo("Closed housing height", base_height + lid_height - joint_overlap);
echo("Top PCB Z allowance", top_board_stack);
echo("Lid skirt wall thickness", joint_step - joint_clearance);

// Output selector
if (selected_part == 1 || output_mode == "base") {
    base_model();
}
else if (selected_part == 2 || output_mode == "lid") {
    lid_model();
}
else if (selected_part == 3 || output_mode == "print_layout") {
    translate([-(case_size_xy[0] + band_lug_extension + 10) / 2, 0, 0])
        base_model();
    translate([(case_size_xy[0] + band_lug_extension + 10) / 2, 0, 0])
        lid_model();
}
else if (selected_part == 4 || output_mode == "fit_preview") {
    spacing = case_size_xy[0] + 2 * band_lug_extension + 16;
    translate([-spacing / 2, 0, 0]) {
        color([0.80, 0.82, 0.86, 1.0]) base_model();
        if (show_component_ghosts) base_component_ghosts();
    }
    translate([spacing / 2, 0, 0]) {
        color([0.92, 0.92, 0.94, 1.0]) lid_model();
        if (show_component_ghosts) lid_component_ghosts();
    }
}
else if (selected_part == 5 || output_mode == "exploded") {
    color([0.80, 0.82, 0.86, 1.0]) base_model();
    color([0.92, 0.92, 0.94, 0.92]) lid_in_assembly(explode_gap);
}
else {
    color([0.80, 0.82, 0.86, 1.0]) base_model();
    color([0.92, 0.92, 0.94, 1.0]) lid_in_assembly();
}
