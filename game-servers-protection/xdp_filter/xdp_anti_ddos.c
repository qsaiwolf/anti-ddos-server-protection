#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>

#ifndef __constant_htons
#define __constant_htons(x) __builtin_bswap16(x)
#endif
#ifndef __constant_ntohs
#define __constant_ntohs(x) __builtin_bswap16(x)
#endif

// Max UDP packets per second per IP (Anti IP-Spoofing)
#define MAX_UDP_PPS_PER_IP 5000
// Max global UDP packets per second (Anti Massive Volumetric floods)
#define MAX_GLOBAL_UDP_PPS 1000000
#define ONE_SEC_NS 1000000000ULL

struct rate_state {
    __u64 last_time;
    __u64 count;
};

// Map to track per-IP packet rates using an LRU cache (evicts old IPs automatically)
struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 100000); // Track up to 100,000 concurrent IPs
    __type(key, __u32);
    __type(value, struct rate_state);
} ip_rate_limit_map SEC(".maps");

// Map to track global UDP packet rate (single entry)
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct rate_state);
} global_rate_limit_map SEC(".maps");

SEC("xdp")
int xdp_prog(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    struct ethhdr *eth = data;
    if (data + sizeof(struct ethhdr) > data_end)
        return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(struct ethhdr);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    // Only apply rate limiting and frag dropping to UDP
    if (ip->protocol != IPPROTO_UDP)
        return XDP_PASS;

    // Drop fragmented UDP packets (only if it's not the first fragment)
    if (ip->frag_off & __constant_htons(IP_OFFSET)) {
        return XDP_DROP;
    }

    struct udphdr *udp = (void *)ip + (ip->ihl * 4);
    if ((void *)(udp + 1) > data_end)
        return XDP_PASS;

    // Drop unusually large UDP packets (likely amplification like Memcached/NTP)
    if (__constant_ntohs(ip->tot_len) > 1200) {
        return XDP_DROP;
    }

    __u64 now = bpf_ktime_get_ns();
    __u32 global_key = 0;
    
    // 1. Global Rate Limiting Logic (Anti-Massive Spoofed Flood)
    struct rate_state *global_state = bpf_map_lookup_elem(&global_rate_limit_map, &global_key);
    if (global_state) {
        if (now - global_state->last_time > ONE_SEC_NS) {
            global_state->count = 1;
            global_state->last_time = now;
        } else {
            __sync_fetch_and_add(&global_state->count, 1);
            if (global_state->count > MAX_GLOBAL_UDP_PPS) {
                return XDP_DROP; // Server is under catastrophic UDP flood, drop everything
            }
        }
    }

    // 2. Per-IP Rate Limiting Logic (Anti-Spoofing / Directed Flood)
    __u32 src_ip = ip->saddr;
    struct rate_state *ip_state = bpf_map_lookup_elem(&ip_rate_limit_map, &src_ip);
    if (ip_state) {
        if (now - ip_state->last_time > ONE_SEC_NS) {
            ip_state->count = 1;
            ip_state->last_time = now;
        } else {
            ip_state->count++;
            if (ip_state->count > MAX_UDP_PPS_PER_IP) {
                return XDP_DROP;
            }
        }
    } else {
        struct rate_state new_state = { .last_time = now, .count = 1 };
        bpf_map_update_elem(&ip_rate_limit_map, &src_ip, &new_state, BPF_ANY);
    }

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
