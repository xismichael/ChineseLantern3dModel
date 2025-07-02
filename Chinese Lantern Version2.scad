

/* [Main Parameters] */
base_diameter = 50;       // Diameter at top and bottom (mm)
lantern_height = 70;      // Total height (mm)
paper_thickness = 0.8;    // Wall thickness (mm)

/* [Frame Settings] */
bulge_factor = 1.2;       // Middle bulge factor (1.0-1.5)
rib_count = 14;           // Number of ribs
rib_thickness = 2.0;      // Rib thickness (mm)

/* [Paper Rib Effect] */
rib_amplitude = 1.5;      // Paper bulge height between ribs (mm)
rib_width = 3.0;          // Width of each bulge (mm)

/* [Handle Settings] */
handle_height = 20;       // Handle arch height (mm)
handle_thickness = 4;     // Handle thickness (mm)

/* [Tassel Settings] */
tassel_length = 60;       // Tassel length (mm)
tassel_count = 12;        // Number of tassel strands

/* [Component Toggles] */
show_paper = true;        // Show paper shell
show_frame = true;        // Show internal frame
show_handle = true;       // Show top handle
show_tassel = true;       // Show bottom tassel

function radius_at_height(z) = 
    let(
        t = z / lantern_height,
        bulge = bulge_factor * pow(cos(180 * (t - 0.5)), 2)
    )
    (base_diameter / 2) * (1 + bulge);


module paper_shell() {
    
    difference() {
        
        rotate_extrude($fn = 120) {
            points = [
                [0, 0],
                for (z = [0:2:lantern_height]) [radius_at_height(z), z],
                [0, lantern_height]
            ];
            polygon(points);
        }
        
        
        translate([0, 0, -0.1])
        rotate_extrude($fn = 120) {
            points = [
                [0, -0.1],
                for (z = [-0.1:2:lantern_height+0.1]) 
                    [max(radius_at_height(z) - paper_thickness, 0.1), z],
                [0, lantern_height+0.1]
            ];
            polygon(points);
        }
    }
    
 
    if (rib_amplitude > 0) {
        for(i = [0:360/rib_count:359]) {
            
            angle = i + 180/rib_count;
            
            
            rotate([0, 0, angle])
            translate([0, 0, -0.1])
            linear_extrude(lantern_height + 0.2) {
                
                offset(r = rib_width/2) {
                    polygon(points = [
                        [0, 0],
                        [rib_amplitude, rib_width/2],
                        [0, rib_width],
                        [-rib_amplitude, rib_width/2]
                    ]);
                }
            }
        }
    }
    
    
    for(i = [0:360/10:359]) rotate([0, 0, i]) {
        translate([0, 0, lantern_height * 0.8])
        linear_extrude(paper_thickness * 3, convexity = 10)
        scale([0.5, 1, 1])
        circle(d = 12, $fn = 32);
    }
}


module internal_frame() {
    
    for(i = [0:360/rib_count:359]) rotate([0, 0, i]) {
        for (z = [0:2:lantern_height-1]) {
            hull() {
                r1 = radius_at_height(z) - paper_thickness;
                translate([r1, 0, z])
                sphere(d = rib_thickness, $fn = 20);
                
                r2 = radius_at_height(z + 2) - paper_thickness;
                translate([r2, 0, z + 2])
                sphere(d = rib_thickness, $fn = 20);
            }
        }
    }
    
   
    color("gold") {
        
        translate([0, 0, lantern_height])
        rotate_extrude($fn = 120)
        translate([radius_at_height(lantern_height) - paper_thickness, 0, 0])
        circle(d = rib_thickness, $fn = 20);
        
        // 底部圆环
        rotate_extrude($fn = 120)
        translate([radius_at_height(0) - paper_thickness, 0, 0])
        circle(d = rib_thickness, $fn = 20);
    }
}


module top_handle() {
    top_radius = radius_at_height(lantern_height) - paper_thickness;
    handle_width = top_radius * 1.8;
    
    translate([0, 0, lantern_height]) {
        rotate([90, 0, 0])
        rotate_extrude(angle = 180, $fn = 64)
        translate([handle_width/2, 0, 0])
        circle(d = handle_thickness, $fn = 20);
        
        for(i = [-1, 1]) {
            translate([i * top_radius, 0, 0])
            cylinder(d = rib_thickness * 1.5, h = 3, $fn = 20);
        }
    }
}


module centered_tassel() {
    // 穗头
    translate([0, 0, -5])
    sphere(d = 10, $fn = 32);
    
    // 穗线
    for(i = [0:360/tassel_count:359]) {
        angle = i;
        dir_x = sin(angle);
        dir_y = cos(angle);
        
        points = [
            [0, 0, -5],
            [dir_x * 5, dir_y * 5, -15],
            [dir_x * 10, dir_y * 10, -30],
            [dir_x * 12, dir_y * 12, -tassel_length]
        ];
        
        for (j = [0 : len(points)-2]) {
            hull() {
                translate(points[j]) sphere(d = 1.0, $fn = 12);
                translate(points[j+1]) sphere(d = (j == len(points)-2 ? 2.5 : 1.0), $fn = 12);
            }
        }
        
        translate(points[len(points)-1])
        sphere(d = 4, $fn = 16);
    }
    
    // 中心穗绳
    color("gold")
    translate([0, 0, -5])
    cylinder(d = 1.0, h = tassel_length, $fn = 12);
}


union() {
    // 纸壳
    if(show_paper) color("red", 0.7) paper_shell();
    
    // 内部框架
    if(show_frame) color("gold") internal_frame();
    
    // 顶部手柄
    if(show_handle) color("gold") top_handle();
    
    // 中心穗子
    if(show_tassel) color("darkred") centered_tassel();
}